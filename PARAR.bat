@echo off
chcp 65001 >nul
title Parar Sistema

echo.
echo ========================================
echo   PARANDO SISTEMA
echo ========================================
echo.

echo Parando processos...
taskkill /IM node.exe /F >nul 2>&1
taskkill /IM python.exe /F >nul 2>&1

echo Sistema parado!

pause