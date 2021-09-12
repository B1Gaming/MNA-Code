class RandTileGenerator
	Types = [:none, :horz, :vert, :both]
	Specials = [nil, :vdouble_top, :vdouble_bottom]

	def initialize
		@sections = {}
	end

	def section(*namelist)
		raise "what" unless namelist.all?{|x| x.is_a?(String)}
		@current_section = (@sections[namelist] ||= {entries: []})
		yield
	end

	def random(range, type=:both, numbers=nil)
		case range
		when Range
			# Regular handling
			numbers = range if numbers.nil?
			@current_section[:entries] << {range: range, type: type, numbers: numbers.to_a}
		when Numeric
			# One number
			random(range..range, type, numbers)
		when Enumerable
			# An array or something else similar
			numbers = range if numbers.nil?
			range.each { |r| random(r, type, numbers) }
		end
	end

	def pack
		# first, work out an offset for every section and entry
		# also, collect the data for each individual entry into an Array
		current_offset = 8 + (@sections.count * 4)
		all_entry_data = []

		@sections.each_pair do |name, section|
			section[:offset] = current_offset
			current_offset += 8

			section[:entries].each do |entry|
				entry[:offset] = current_offset
				all_entry_data << entry[:numbers]
				current_offset += 8
			end
		end

		# assign an offset to each section name list
		namelist_offsets = {}
		@sections.each_key do |namelist|
			namelist_offsets[namelist] = current_offset
			current_offset += 4 + (4 * namelist.size)
		end

		# assign an offset to each piece of entry data
		data_offsets = {}
		all_entry_data.uniq!

		all_entry_data.each do |data|
			data_offsets[data] = current_offset
			current_offset += data.size
		end

		# assign an offset to each section name
		name_offsets = {}
		@sections.each_key do |namelist|
			namelist.each do |name|
				name_offsets[name] = current_offset
				current_offset += name.size + 1
			end
		end

		# now pack it all together
		header = ['NwRT', @sections.count].pack('a4 N')
		offsets = @sections.each_value.map{|s| s[:offset]}.pack('N*')

		section_data = @sections.each_pair.map do |namelist, section|
			namelist_offset = namelist_offsets[namelist] - section[:offset]
			entry_count = section[:entries].count

			entry_data = section[:entries].map do |entry|
				lower_bound = entry[:range].min
				upper_bound = entry[:range].max

				count = entry[:numbers].count

				type_sym, special_sym = entry[:type].to_s.split('_', 2).map(&:to_sym)
				type_id = Types.index(type_sym)
				special_id = Specials.index(special_sym)
				type = type_id | (special_id << 2)

				num_offset = data_offsets[entry[:numbers]] - entry[:offset]

				[lower_bound, upper_bound, count, type, num_offset].pack('CCCC N')
			end

			[namelist_offset, entry_count].pack('NN') + entry_data.join
		end

		namelist_data = @sections.each_key.map do |namelist|
			puts "Writing list: #{namelist.inspect}"
			count = namelist.size
			c_offsets = namelist.map{|n| name_offsets[n] - namelist_offsets[namelist]}
			puts "Offsets: #{c_offsets.inspect}"

			[count].pack('N') + c_offsets.pack('N*')
		end

		output = [header, offsets]
		output += section_data
		output += namelist_data
		output += all_entry_data.map{|data| data.pack('C*')}
		output << @sections.keys.flatten.join("\0")
		output << "\0"
		output.join
	end


	def regular_terrain
		# Left Side
		random([0x10, 0x20, 0x30, 0x40], :vert)
		# Right Side
		random([0x11, 0x21, 0x31, 0x41], :vert)
		# Top Side
		random(2..7, :horz)
		# Bottom Side
		random(0x22..0x27, :horz)
		# Middle
		random(0x12..0x17)
	end

	def sub_terrain
		# Left Side
		random([0x18, 0x28, 0x38, 0x48], :vert)
		# Right Side
		random([0x19, 0x29, 0x39, 0x49], :vert)
		# Top Side
		random(0xA..0xF, :horz)
		# Bottom Side
		random(0x2A..0x2F, :horz)
		# Middle
		random(0x1A..0x1F)
	end

	def regular_u_terrain
		# Top Side
		random(0x02..0x05, :horz)
		# Middle
		random(0x12..0x15)
		# Bottom Side
		random(0x22..0x25, :horz)
		# Left Side
		random([0x10, 0x20, 0x30, 0x40], :vert)
		# Right Side
		random([0x11, 0x21, 0x31, 0x41], :vert)
	end
end


g = RandTileGenerator.new
g.section('TestTileset') do
	g.random(1..20)
	g.random(21..24, :none)
	g.random(250..255, :vert, 0..5)
end

regular_ts1 = %w(suichu)
regular_ts1 += %w(dokan_naibu nohara2 shiro_koopa)
regular_ts2 = %w(doukutu doukutu2 doukutu3 doukutu4 doukutu5 doukutu6 doukutu7 doukutu8)
newer = %w(Pa1_supesu Pa1_totemu)
newer += %w(none)

regular_ts1.map!{ |x| "Pa1_#{x}" }
regular_ts2.map!{ |x| "Pa2_#{x}" }
g.section(*regular_ts1, *regular_ts2, *newer) do
	g.regular_terrain
end

nohara_clones = %w(nohara)
g.section(*nohara_clones.map{ |x| "Pa1_#{x}"}) do
	g.regular_terrain
	g.sub_terrain
end

g.section('Pa1_aki') do
	g.random(0x2..0x7, :horz_vdouble_top)
	g.random(0x12..0x17, :horz_vdouble_bottom)
	g.random(0x22..0x27)
	g.random(0x32..0x37)
	g.random([0x20, 0x30, 0x40, 0x50], :vert)
	g.random([0x21, 0x31, 0x41, 0x51], :vert)
end

g.section('Pa1_chika', 'Pa1_sabaku_chika', 'Pa1_kurayami_chika', 'Pa1_kurisutaru_chika') do
	g.regular_terrain
	g.random(0x0A..0x0F, :horz)
	g.random(0x1A..0x1F, :horz)
end

g.section('Pa1_daishizenplus') do
	g.regular_terrain
	g.random(0xF6..0xF8, :horz)
end

g.section('Pa1_freezeflame') do
	g.regular_terrain
	g.sub_terrain
	g.random(0xA2..0xA7, :horz)
	g.random(0xB2..0xB7)
	g.random(0xC2..0xC7, :horz)
	g.random([0xB0, 0xC0, 0xD0, 0xE0], :vert)
	g.random([0xB1, 0xC1, 0xD1, 0xE1], :vert)
	g.random(0xAA..0xAF, :horz)
	g.random(0xBA..0xBF)
	g.random(0xCA..0xCF, :horz)
	g.random([0xB8, 0xC8, 0xD8, 0xE8], :vert)
	g.random([0xB9, 0xC9, 0xD9, 0xE9], :vert)
end

g.section('Pa1_gake', 'Pa1_gake_setsugen') do
	g.regular_terrain
	g.sub_terrain
	g.random([0x36, 0x37, 0x46, 0x47, 0x56, 0x57], :horz)
	g.random([0x52, 0x53, 0x5A, 0x5B, 0x5C, 0x5D], :horz)
	g.random([0xBA, 0xCA, 0xDA, 0xEA], :vert)
	g.random([0xBB, 0xCB, 0xDB, 0xEB], :vert)
	g.random([0xBC, 0xCC, 0xDC, 0xEC], :vert)
	g.random([0xBD, 0xCD, 0xDD, 0xED], :vert)
end

g.section('Pa1_gake_yougan') do
	g.regular_terrain
	g.random(0x62.. 0x67, :horz)
	g.random([0x70, 0x80, 0x90, 0xA0], :vert)
	g.random([0x71, 0x81, 0x91, 0xA1], :vert)
end

g.section('Pa1_kaigan', 'Pa1_kaigan_taiyo') do
	g.regular_terrain
	g.random(0x18..0x1B)
	g.random(0x28..0x2A)
	g.random(0x3A..0x3D)
end

g.section('Pa1_koopa_out') do
	g.regular_terrain
	g.random([0x18, 0x28, 0x38, 0x48], :vert)
end

g.section('Pa1_korichika') do
	g.regular_terrain
	g.sub_terrain
	g.random(0x0A..0x0F, :horz)
	g.random(0xAA..0xAF, :horz)
	g.random(0xBA..0xBF, :horz)
	g.random([0xB8, 0xC8, 0xD8, 0xE8], :vert)
	g.random([0xB9, 0xC9, 0xD9, 0xE9], :vert)
end

g.section('Pa1_obake_soto') do
	g.random(0x0A..0x0F, :horz)
	g.random(0x1A..0x1F)
	g.random(0x2A..0x2F, :horz)
	g.random([0x4E, 0x5E, 0x6E, 0x7E], :vert)
	g.random([0x4F, 0x5F, 0x6F, 0x7F], :vert)
end

g.section('Pa1_obake') do
	g.random(0xA4..0xA6, :horz)
	g.random(0xB4..0xB6)
	g.random(0xC4..0xC6, :horz)
	g.random(0xF0..0xF2)
	g.random(0x18..0x1F, :horz)
	g.random(0xD0..0xD2, :vert)
	g.random(0xE0..0xE2, :vert)
end

g.section('Pa1_sakura') do
	g.regular_terrain
	g.random(0x0A..0x0F, :horz)
end

g.section('Pa1_sabaku') do
	g.random(0x12..0x17)
	g.random(0x22..0x27, :horz)
	g.random([0x10, 0x20, 0x30, 0x40], :vert)
	g.random([0x11, 0x21, 0x31, 0x41], :vert)
	g.random(0xA..0xF, :horz)
end

g.section('Pa1_setsugen') do
	g.regular_terrain
	g.random(0xD2..0xD7)
end

g.section('Pa1_shiro', 'Pa1_shiro_yogan') do
	g.regular_terrain
	g.random(0x0A..0x0F, :horz)
	g.random(0x1A..0x1F, :horz)
	g.random(0x2A..0x2F)
	g.random(0x3A..0x3F, :horz)
	g.random([0x28, 0x38, 0x48, 0x58], :vert)
	g.random([0x29, 0x39, 0x49, 0x59], :vert)
end

g.section('Pa1_shiro_boss1') do
	g.regular_terrain
end

g.section('Pa1_shiro_sora') do
	g.regular_terrain
	g.random(0x0B..0x0E, :horz)
	g.random(0x1B..0x1E)
end

g.section('Pa1_shiro_aki', 'Pa1_shiro_taiyo') do
	g.regular_terrain
	g.random([0xBC, 0xBD, 0xBE, 0xCC, 0xCD, 0xCE, 0xDC, 0xDD, 0xDE, 0xEC, 0xED, 0xEE])
	g.random([0xB9, 0xC9, 0xD9, 0xE9], :vert)
	g.random([0xBA, 0xCA, 0xDA, 0xEA], :vert)
	g.random(0x18..0x1F, :horz)
	g.random(0x48..0x4F, :horz)
end

g.section('Pa2_gake', 'Pa2_gake_setsugen') do
	g.random(0x00..0x05, :horz)
	g.random(0x10..0x15)
	g.random(0x20..0x25, :horz)
	g.random(0x06..0x09, :vert)
	g.random(0x0A..0x0D, :vert)
end

g.section('Pa2_hashi') do
	g.random(0x02..0x07, :horz)
	g.random([0x12, 0x22, 0x32, 0x42, 0x52, 0x62], :vert)
end

g.section('Pa2_kori') do
	g.regular_terrain
	g.random(0xA0..0xA5, :horz)
	g.random(0xB0..0xB5, :horz)
end

g.section('Pa2_toride', 'Pa2_toride_kori', 'Pa2_toride_sabaku', 'Pa2_toride_soto', 'Pa2_toride_yougan') do
	g.random(0x02..0x07, :horz)
	g.random(0x12..0x17, :horz)
	g.random(0x22..0x27)
	g.random(0x32..0x37, :horz)
	g.random([0x20, 0x30, 0x40, 0x50], :vert)
	g.random([0x21, 0x31, 0x41, 0x51], :vert)
end


File.open('E:/NSMBW Modding/NewerDolphin/MNA_FILES/files/NewerRes/RandTiles.bin', 'wb') do |f|
	f.write g.pack
end

