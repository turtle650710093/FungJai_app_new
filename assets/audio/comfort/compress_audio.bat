
@echo off
echo ===================================
echo Audio Compression Script
echo ===================================
echo.

mkdir compressed 2>nul

for %%f in (*.m4a) do (
    echo Processing: %%f
    ffmpeg -i "%%f" -b:a 64k -ar 22050 -y "compressed\%%f"
)

echo.
echo ===================================
echo Done! Check 'compressed' folder
echo File size reduced by ~90%%
echo ===================================
pause