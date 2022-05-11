@ECHO OFF
python makeGame.py NewerProject.yaml
move Build_NewerProject\*.bin "E:\NSMBW Modding\NewerDolphin\User\Load\Riivolution\NewAdventure\NewerRes"
@RD /S /Q "Build_NewerProject"
pause