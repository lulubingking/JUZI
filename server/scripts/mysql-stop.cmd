@echo off
REM ============================================================
REM 橘子手机（JUZI PHONE）开发环境 MySQL 停止脚本
REM 用法：双击运行，或命令行执行 mysql-stop.cmd
REM ============================================================
echo 正在关闭 MySQL（3306）...
"C:\Users\13535\.workbuddy\tools\mysql-8.0.46-winx64\bin\mysqladmin.exe" -h127.0.0.1 -P3306 -uroot shutdown 2>nul
if %errorlevel%==0 (
  echo [OK] MySQL 已正常关闭
) else (
  echo [WARN] 关闭失败（可能未在运行，或需 root 密码）；如无 3306 监听可忽略
)
