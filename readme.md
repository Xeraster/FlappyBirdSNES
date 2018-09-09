The compiled rom file for anyone that wants to just download and play this game in it's current state is "flappy.fig"

If you are looking to make changes to this game to make it better (thanks), then the file that has all the code that you need to compile with the includes wla compiler is "flappy.asm". To compile, open a command prompt and type "wla.bat flappy"

To compile any custom picture maps such as flappy.pcx, run:
pcx2snes.exe flappy -c16 -o128
and then move the files to "Pictures" folder and run "convert_pics.bat"
Refer to the readme file in the "Tools" folder for more information on using pcx2snes.
