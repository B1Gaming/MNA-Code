#include <asm_setup.S>

# Sys functions
.extern DVDClass
.extern GetRes
.extern strcmp

# Code
.extern HasFlowers, NoFlowers
.extern returnFromFlowerBuild1
.extern returnFromFlowerBuild2, returnFromFlowerBuild2ItsGrassland, returnFromFlowerBuild2ItsDaishizen
.extern returnFromFlowerBuild3, returnFromFlowerBuild3ItsGrassland, returnFromFlowerBuild3ItsDaishizen
.extern returnFromFlowerBuild4

# Data
.extern ObjHana, ObjHanaBrres
.extern ObjKusa, ObjKusaBrres
.extern Pa1Daishizen

# Globals
.global FlowerCheck
.global FlowerBuild1, FlowerBuild2, FlowerBuild3, FlowerBuild4

.text
.align 4

# This function checks whether the flowers should be loaded. To make
# your own block, copy the instructions from "mr r3, r26" to "beq true",
# add your tileset's name in the lis and ori instructions, then add
# your tileset to the tileset name list at the end of this file.

FlowerCheck:
	mr r3, r26
	lis r4, Pa1DaishizenPlus@h
	ori r4, r4, Pa1DaishizenPlus@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	mr r3, r26
	lis r4, Pa1Chika@h
	ori r4, r4, Pa1Chika@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	mr r3, r26
	lis r4, Pa1Setsugen@h
	ori r4, r4, Pa1Setsugen@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	mr r3, r26
	lis r4, Pa1ShiroSora@h
	ori r4, r4, Pa1ShiroSora@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	mr r3, r26
	lis r4, Pa1KaiganAoi@h
	ori r4, r4, Pa1KaiganAoi@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	mr r3, r26
	lis r4, Pa1Oashishu@h
	ori r4, r4, Pa1Oashishu@l
	bl strcmp
	cmpwi r3, 0
	beq true
	
	# No flowers detected, sir.
	b NoFlowers

true:
	b HasFlowers


# First branch in the ObjGrass onCreate, which checks the tileset name (again)
# Not gonna write an essay here as well.

FlowerBuild1:
	# Copy of the game's original compare, don't use this as a base!
	mr r26, r3
	addi r4, r31, Pa1Daishizen@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1Daishizen

	# Use this one instead ;)
	mr r3, r26
	lis r4, Pa1DaishizenPlus@h
	ori r4, r4, Pa1DaishizenPlus@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1DaishizenPlus
	
	mr r3, r26
	lis r4, Pa1Chika@h
	ori r4, r4, Pa1Chika@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1Chika
	
	mr r3, r26
	lis r4, Pa1Setsugen@h
	ori r4, r4, Pa1Setsugen@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1Setsugen
	
	mr r3, r26
	lis r4, Pa1ShiroSora@h
	ori r4, r4, Pa1ShiroSora@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1ShiroSora
	
	mr r3, r26
	lis r4, Pa1KaiganAoi@h
	ori r4, r4, Pa1KaiganAoi@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1KaiganAoi
	
	mr r3, r26
	lis r4, Pa1Oashishu@h
	ori r4, r4, Pa1Oashishu@l
	bl strcmp
	cmpwi r3, 0
	beq IsPa1Oashishu
	
	# Return otherwise
	b returnFromFlowerBuild1

# The value in r28 will be reused in later checks, so add a copy of this as well
IsPa1Daishizen:
	li r28, 1
	b returnFromFlowerBuild1

IsPa1DaishizenPlus:
	li r28, 2
	b returnFromFlowerBuild1

IsPa1Chika:
	li r28, 3
	b returnFromFlowerBuild1

IsPa1Setsugen:
	li r28, 4
	b returnFromFlowerBuild1

IsPa1ShiroSora:
	li r28, 5
	b returnFromFlowerBuild1

IsPa1KaiganAoi:
	li r28, 6
	b returnFromFlowerBuild1

IsPa1Oashishu:
	li r28, 7
	b returnFromFlowerBuild1


# First of the three arc file loaders. Loads the brres file based on r28's content.
FlowerBuild2:
	cmpwi r28, 0
	beq ItsGrassland
	cmpwi r28, 1
	beq ItsDaishizen
	cmpwi r28, 2
	beq ItsDaishizenPlus
	cmpwi r28, 3
	beq ItsChika
	cmpwi r28, 4
	beq ItsSetsugen
	cmpwi r28, 5
	beq ItsShiroSora
	cmpwi r28, 6
	beq ItsKaiganAoi
	cmpwi r28, 7
	beq ItsOashishu
	b returnFromFlowerBuild2

ItsGrassland:
	b returnFromFlowerBuild2ItsGrassland

ItsDaishizen:
	b returnFromFlowerBuild2ItsDaishizen

# Copy this block!
ItsDaishizenPlus:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaDai@h
	ori r5, r5, ObjHanaDai@l
	bl GetRes
	b returnFromFlowerBuild2

ItsChika:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaChi@h
	ori r5, r5, ObjHanaChi@l
	bl GetRes
	b returnFromFlowerBuild2

ItsSetsugen:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKog@h
	ori r5, r5, ObjHanaKog@l
	bl GetRes
	b returnFromFlowerBuild2

ItsShiroSora:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKog@h
	ori r5, r5, ObjHanaKog@l
	bl GetRes
	b returnFromFlowerBuild2

ItsKaiganAoi:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKao@h
	ori r5, r5, ObjHanaKao@l
	bl GetRes
	b returnFromFlowerBuild2

ItsOashishu:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaOas@h
	ori r5, r5, ObjHanaOas@l
	bl GetRes
	b returnFromFlowerBuild2


# Another arc file swapper, no idea why there are two.
FlowerBuild3:
	cmpwi r28, 0
	beq ItsGrassland3
	cmpwi r28, 1
	beq ItsDaishizen3
	cmpwi r28, 2
	beq ItsDaishizenPlus3
	cmpwi r28, 3
	beq ItsChika3
	cmpwi r28, 4
	beq ItsSetsugen3
	cmpwi r28, 5
	beq ItsShiroSora3
	cmpwi r28, 6
	beq ItsKaiganAoi3
	cmpwi r28, 7
	beq ItsOashishu3
	b returnFromFlowerBuild2

ItsGrassland3:
	b returnFromFlowerBuild3ItsGrassland

ItsDaishizen3:
	b returnFromFlowerBuild3ItsDaishizen

ItsDaishizenPlus3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaDai@h
	ori r5, r5, ObjHanaDai@l
	bl GetRes
	b returnFromFlowerBuild3

ItsChika3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaChi@h
	ori r5, r5, ObjHanaChi@l
	bl GetRes
	b returnFromFlowerBuild3

ItsSetsugen3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKog@h
	ori r5, r5, ObjHanaKog@l
	bl GetRes
	b returnFromFlowerBuild3

ItsShiroSora3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKog@h
	ori r5, r5, ObjHanaKog@l
	bl GetRes
	b returnFromFlowerBuild3

ItsKaiganAoi3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaKao@h
	ori r5, r5, ObjHanaKao@l
	bl GetRes
	b returnFromFlowerBuild3

ItsOashishu3:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjHana@h
	ori r4, r4, ObjHana@l
	lis r5, ObjHanaOas@h
	ori r5, r5, ObjHanaOas@l
	bl GetRes
	b returnFromFlowerBuild3

# This check is used for the grass. Since the game originally doesn't perform
# a check on r28, we'll do it ourselves.
FlowerBuild4:
	cmpwi r28, 1
	ble ItsGrassOrDaishizen
	cmpwi r28, 2
	beq ItsDaishizenPlus4
	cmpwi r28, 3
	beq ItsChika4
	cmpwi r28, 4
	beq ItsSetsugen4
	cmpwi r28, 5
	beq ItsShiroSora4
	cmpwi r28, 6
	beq ItsKaiganAoi4
	cmpwi r28, 7
	beq ItsOashishu4
	b returnFromFlowerBuild2

# Copypasted code, do NOT use!
ItsGrassOrDaishizen:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaBrres@h
	ori r5, r5, ObjKusaBrres@l
	bl GetRes
	b returnFromFlowerBuild4

# Use this block instead ;)
ItsDaishizenPlus4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaDai@h
	ori r5, r5, ObjKusaDai@l
	bl GetRes
	b returnFromFlowerBuild4

ItsChika4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaChi@h
	ori r5, r5, ObjKusaChi@l
	bl GetRes
	b returnFromFlowerBuild4

ItsSetsugen4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaKog@h
	ori r5, r5, ObjKusaKog@l
	bl GetRes
	b returnFromFlowerBuild4

ItsShiroSora4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaKog@h
	ori r5, r5, ObjKusaKog@l
	bl GetRes
	b returnFromFlowerBuild4

ItsKaiganAoi4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaKao@h
	ori r5, r5, ObjKusaKao@l
	bl GetRes
	b returnFromFlowerBuild4

ItsOashishu4:
	lis r3, DVDClass@ha
	lwz r3, DVDClass@l(r3)
	addi r3, r3, 4
	lis r4, ObjKusa@h
	ori r4, r4, ObjKusa@l
	lis r5, ObjKusaOas@h
	ori r5, r5, ObjKusaOas@l
	bl GetRes
	b returnFromFlowerBuild4

.data
.align 4

# Tilesets go here
Pa1DaishizenPlus: .string 'Pa1_daishizenplus'
Pa1Chika: .string 'Pa1_chika'
Pa1Setsugen: .string 'Pa1_setsugen'
Pa1ShiroSora: .string 'Pa1_shiro_sora'
Pa1KaiganAoi: .string 'Pa1_kaigan_aoi'
Pa1Oashishu: .string 'Pa1_oashishu'

# Flower brres files go here
ObjHanaDai: .string 'g3d/obj_hana_dai.brres'
ObjHanaChi: .string 'g3d/obj_hana_chi.brres'
ObjHanaKog: .string 'g3d/obj_hana_kog.brres'
ObjHanaKao: .string 'g3d/obj_hana.brres'
ObjHanaOas: .string 'g3d/obj_hana.brres'

# Grass brres files go here
ObjKusaDai: .string 'g3d/obj_kusa_dai.brres'
ObjKusaChi: .string 'g3d/obj_kusa_chi.brres'
ObjKusaKog: .string 'g3d/obj_kusa_kog.brres'
ObjKusaKao: .string 'g3d/obj_kusa.brres'
ObjKusaOas: .string 'g3d/obj_kusa.brres'