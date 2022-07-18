from __future__ import annotations
from enum import IntEnum
from collections import defaultdict
from collections.abc import Sequence
import struct

class RandMode(IntEnum):
    NONE = 0
    HORZ = 1
    VERT = 2
    BOTH = 3

class SpecialFeature(IntEnum):
    NONE = 0
    VDOUBLE_TOP = 1
    VDOUBLE_BOTTOM = 2


class Entry:
    source_tiles: list[tuple[int, int]]
    target_tiles: tuple[int, ...]
    mode: RandMode = RandMode.BOTH
    special: SpecialFeature = SpecialFeature.NONE
    offset: int = 0 # used when packing

    def __init__(self, source_tiles: list[tuple[int, int]], target_tiles: tuple[int, ...]):
        self.source_tiles = source_tiles
        self.target_tiles = target_tiles

    def mode_none(self) -> Entry:
        '''Disables checks, allowing identical tiles to appear next to each other on any axis'''
        self.mode = RandMode.NONE
        return self
    def mode_horz(self) -> Entry:
        '''Sets horizontal mode, which stops two identical tiles from appearing side-by-side'''
        self.mode = RandMode.HORZ
        return self
    def mode_vert(self) -> Entry:
        '''Sets vertical mode, which stops two identical tiles from appearing in a column'''
        self.mode = RandMode.VERT
        return self
    def vdouble_top(self) -> Entry:
        '''Marks this tile as the top part in a 1x2 randomisation'''
        self.special = SpecialFeature.VDOUBLE_TOP
        return self
    def vdouble_bottom(self) -> Entry:
        '''Marks this tile as the bottom part in a 1x2 randomisation'''
        self.special = SpecialFeature.VDOUBLE_BOTTOM
        return self

    def set_target_range(self, start: int, end: int) -> Entry:
        '''Assign a contiguous range of output tiles that this randomisation will produce'''
        self.target_tiles = tuple(range(start, end + 1))
        return self
    def set_target_tiles(self, *numbers: int) -> Entry:
        '''Assign a list of output tiles that this randomisation will produce'''
        self.target_tiles = numbers
        return self


class Section:
    entries: list[Entry]
    offset: int = 0 # used when packing

    def __init__(self):
        self.entries = []

    def add_range(self, start: int, end: int) -> Entry:
        '''Add a mapping for a range of contiguous tile IDs'''
        e = Entry([(start, end)], tuple(range(start, end + 1)))
        self.entries.append(e)
        return e

    def add_tile(self, *numbers: int) -> Entry:
        '''Add a mapping for one or more tile IDs'''
        source_tiles = [(n, n) for n in numbers]
        target_tiles = numbers
        e = Entry(source_tiles, target_tiles)
        self.entries.append(e)
        return e

    def add_regular_terrain(self):
        '''Add mappings for Nintendo's #1 tile arrangement (as seen in Pa1_nohara, etc for the main terrain)'''
        # Left Side
        self.add_tile(0x10, 0x20, 0x30, 0x40).mode_vert()
        # Right Side
        self.add_tile(0x11, 0x21, 0x31, 0x41).mode_vert()
        # Top Side
        self.add_range(2, 7).mode_horz()
        # Bottom Side
        self.add_range(0x22, 0x27).mode_horz()
        # Middle
        self.add_range(0x12, 0x17)

    def add_sub_terrain(self):
        '''Add mappings for Nintendo's #2 tile arrangement (as seen in Pa1_nohara, etc for solid-on-top tiles)'''
        # Left Side
        self.add_tile(0x18, 0x28, 0x38, 0x48).mode_vert()
        # Right Side
        self.add_tile(0x19, 0x29, 0x39, 0x49).mode_vert()
        # Top Side
        self.add_range(0xA, 0xF).mode_horz()
        # Bottom Side
        self.add_range(0x2A, 0x2F).mode_horz()
        # Middle
        self.add_range(0x1A, 0x1F)


class RandTileGenerator:
    sections: defaultdict[tuple[str, ...], Section]

    def __init__(self):
        self.sections = defaultdict(Section)

    def section(self, *names: str) -> Section:
        '''Add a section for one or more tilesets'''
        return self.sections[names]

    def pack(self) -> bytes:
        '''Create a binary blob from this generator'''
        current_offset = 8 + (len(self.sections) * 4)
        all_entry_data: list[tuple[int, ...]] = []

        # first, work out an offset for every section and entry
        # also, collect the data for each individual entry into a list
        for _, section in self.sections.items():
            section.offset = current_offset
            current_offset += 8

            for entry in section.entries:
                entry.offset = current_offset
                all_entry_data.append(entry.target_tiles)
                current_offset += 8 * len(entry.source_tiles)

        # assign an offset to each section name list
        namelist_offsets = {}
        for namelist in self.sections.keys():
            namelist_offsets[namelist] = current_offset
            current_offset += 4 + (4 * len(namelist))

        # assign an offset to each piece of entry data
        data_offsets = {}
        all_entry_data = list(set(all_entry_data)) # eliminate duplicates
        for data in all_entry_data:
            data_offsets[data] = current_offset
            current_offset += len(data)

        # assign an offset to each section name
        name_offsets = {}
        string_table = []
        for namelist in self.sections.keys():
            for name in namelist:
                name_offsets[name] = current_offset
                name = name.encode('ascii') + b'\0'
                string_table.append(name)
                current_offset += len(name)

        # now pack it all together
        u32 = struct.Struct('>I')
        header = [b'NwRT', u32.pack(len(self.sections))]
        offsets = []
        section_data = []
        namelist_data = []

        for namelist, section in self.sections.items():
            offsets.append(u32.pack(section.offset))

            # section_data
            namelist_offset = namelist_offsets[namelist] - section.offset
            entry_count = 0
            entry_data = []

            for entry in section.entries:
                count = len(entry.target_tiles)
                type_value = int(entry.mode) | (int(entry.special) << 2)
                # create one entry in the file for each source_tiles pair
                work_offset = entry.offset
                for lower_bound, upper_bound in entry.source_tiles:
                    num_offset = data_offsets[entry.target_tiles] - work_offset
                    entry_data.append(struct.pack('>BBBBI', lower_bound, upper_bound, count, type_value, num_offset))
                    work_offset += 8
                    entry_count += 1

            section_data.append(u32.pack(namelist_offset))
            section_data.append(u32.pack(entry_count))
            section_data.extend(entry_data)

            # namelist_data
            namelist_data.append(u32.pack(len(namelist)))
            for name in namelist:
                namelist_data.append(u32.pack(name_offsets[name] - namelist_offsets[namelist]))

        # final
        output = header
        output.extend(offsets)
        output.extend(section_data)
        output.extend(namelist_data)
        for data in all_entry_data:
            output.append(bytes(data))
        output.extend(string_table)
        return b''.join(output)



g = RandTileGenerator()
s = g.section('TestTileset')
s.add_range(1, 20)
s.add_range(21, 24).mode_none()
s.add_range(250, 255).mode_vert().set_target_range(0, 5)

regular_ts1 = 'aki daishizenplus dokan_naibu obake shiro shiro_aki shiro_boss1 shiro_koopa shiro_sora shiro_soto shiro_taiyo shiro_yogan suichu'.split(' ')
regular_ts1 += 'dokan_naibu nohara2'.split(' ')
regular_ts1 = ['Pa1_' + x for x in regular_ts1]

regular_ts2 = 'doukutu doukutu2 doukutu3 doukutu4 doukutu5 doukutu6 doukutu7 doukutu8 doukutu9'.split(' ')
regular_ts2 = ['Pa2_' + x for x in regular_ts2]

newer = 'Pa1_supesu'.split(' ')
newer += 'none'.split(' ')

s = g.section(*regular_ts1, *regular_ts2, *newer)
s.add_regular_terrain()

nohara_clones = 'nohara supesu'.split(' ')
s = g.section(*['Pa1_' + x for x in nohara_clones])
s.add_regular_terrain()
s.add_sub_terrain()

s = g.section('Pa1_autumnmega')
s.add_range(2, 7).vdouble_top()
s.add_range(0x12, 0x17).vdouble_bottom()
s.add_range(0xB0, 0xDF)
s.add_range(0x22, 0x27).mode_horz()
s.add_tile(0x20, 0x30, 0x40).mode_vert()
s.add_tile(0x21, 0x31, 0x41).mode_vert()
s.add_range(0xA, 0xF).vdouble_top()
s.add_range(0x1A, 0x1F).vdouble_bottom()
s.add_tile(0x39, 0x49, 0x59)
s.add_range(0x2A, 0x2F).mode_horz()
s.add_tile(0x3E, 0x4E, 0x5E).mode_vert()
s.add_tile(0x3F, 0x4F, 0x5F).mode_vert()

s = g.section('Pa1_chika', 'Pa1_sabaku_chika', 'Pa1_kurayami_chika', 'Pa1_kurisutaru_chika')
s.add_regular_terrain()
s.add_range(0x0A, 0x0F)
s.add_range(0x1A, 0x1F)

s = g.section('Pa1_daishizenplus')
s.add_regular_terrain()
s.add_range(0xF6, 0xF8).mode_horz()

s = g.section('Pa1_freezeflame')
s.add_regular_terrain()
s.add_sub_terrain()
s.add_range(0x4A, 0x4F).mode_horz()
s.add_range(0xA2, 0xA7).mode_horz()
s.add_range(0xB2, 0xB7)
s.add_range(0xC2, 0xC7).mode_horz()
s.add_tile(0xB0, 0xC0, 0xD0, 0xE0).mode_vert()
s.add_tile(0xB1, 0xC1, 0xD1, 0xE1).mode_vert()
s.add_range(0xAA, 0xAF).mode_horz()
s.add_range(0xBA, 0xBF)
s.add_range(0xCA, 0xCF).mode_horz()
s.add_tile(0xB8, 0xC8, 0xD8, 0xE8).mode_vert()
s.add_tile(0xB9, 0xC9, 0xD9, 0xE9).mode_vert()

s = g.section('Pa1_gake', 'Pa1_gake_setsugen')
s.add_regular_terrain()
s.add_sub_terrain()
s.add_tile(0x36, 0x37, 0x46, 0x47, 0x56, 0x57).mode_horz()
s.add_tile(0x52, 0x53, 0x5A, 0x5B, 0x5C, 0x5D).mode_horz()
s.add_tile(0xBA, 0xCA, 0xDA, 0xEA).mode_vert()
s.add_tile(0xBB, 0xCB, 0xDB, 0xEB).mode_vert()
s.add_tile(0xBC, 0xCC, 0xDC, 0xEC).mode_vert()
s.add_tile(0xBD, 0xCD, 0xDD, 0xED).mode_vert()

s = g.section('Pa1_gake_yougan')
s.add_regular_terrain()
s.add_range(0x62, 0x67).mode_horz()
s.add_tile(0x70, 0x80, 0x90, 0xA0).mode_vert()
s.add_tile(0x71, 0x81, 0x91, 0xA1).mode_vert()

s = g.section('Pa1_jungleruins')
s.add_range(0x02, 0x07).mode_horz()

s = g.section('Pa1_kaigan', 'Pa1_kaigan_taiyo')
s.add_regular_terrain()
s.add_range(0x08, 0x0B)
s.add_range(0x18, 0x1B)
s.add_range(0x28, 0x2A).mode_horz()
s.add_range(0x3A, 0x3D).mode_horz()

s = g.section('Pa1_koopa_out')
s.add_regular_terrain()
s.add_tile(0x18, 0x28, 0x38, 0x48).mode_vert()
s.add_range(0x66, 0x6B).mode_horz()

s = g.section('Pa1_korichika')
s.add_regular_terrain()
s.add_sub_terrain()
s.add_range(0xAA, 0xAF).mode_horz()
s.add_range(0xBA, 0xBF).mode_horz()
s.add_tile(0xB8, 0xC8, 0xD8, 0xE8).mode_vert()
s.add_tile(0xB9, 0xC9, 0xD9, 0xE9).mode_vert()

s = g.section('Pa1_kaigan_aoi', 'Pa1_oashishu')
s.add_regular_terrain()
s.add_range(0x18, 0x1D)
s.add_range(0x28, 0x2A).mode_horz()
s.add_range(0x3A, 0x3D).mode_horz()

s = g.section('Pa1_obake_soto')
s.add_range(0x0A, 0x0F).mode_horz()
s.add_range(0x1A, 0x1F)
s.add_range(0x2A, 0x2F).mode_horz()
s.add_tile(0x4E, 0x5E, 0x6E, 0x7E).mode_vert()
s.add_tile(0x4F, 0x5F, 0x6F, 0x7F).mode_vert()

s = g.section('Pa1_sakura')
s.add_regular_terrain()
s.add_range(0x0A, 0x0F).mode_horz()

s = g.section('Pa1_setsugen')
s.add_regular_terrain()
s.add_range(0xD2, 0xD7).mode_horz()

s = g.section('Pa2_hashi')
s.add_range(0x02, 0x07).mode_horz()
s.add_tile(0x12, 0x22, 0x32, 0x42, 0x52, 0x62).mode_vert()

s = g.section('Pa2_kori')
s.add_regular_terrain()
s.add_range(0xA0, 0xA5).mode_horz()
s.add_range(0xB0, 0xB5).mode_horz()

s = g.section('Pa2_toride', 'Pa2_toride_kori', 'Pa2_toride_sabaku', 'Pa2_toride_soto', 'Pa2_toride_yogan')
s.add_range(0x02, 0x07).mode_horz()
s.add_range(0x12, 0x17).mode_horz()
s.add_range(0x22, 0x27)
s.add_range(0x32, 0x37).mode_horz()
s.add_tile(0x20, 0x30, 0x40, 0x50).mode_vert()
s.add_tile(0x21, 0x31, 0x41, 0x51).mode_vert()

with open('E:/NSMBW Modding/NewerDolphin/User/Load/Riivolution/NewAdventure/NewerRes/RandTiles.bin', 'wb') as f:
    f.write(g.pack())

