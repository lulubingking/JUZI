@echo off
REM ============================================================
REM 橘子手机（JUZI PHONE）开发环境 MySQL 8.0.46 启动脚本
REM 说明：免安装版（ZIP 解压），数据目录 C:\Users\13535\.workbuddy\mysql-data
REM 用法：双击运行，或命令行执行 mysql-start.cmd（保持窗口开启）
REM 停止：另行运行 mysql-stop.cmd
REM ============================================================
echo [1/2] 检查 MySQL 是否已在运行...
netstat -an | findstr ":3306" | findstr "LISTENING" >nul
if %errorlevel%==0 (
  echo [OK] MySQL 已在运行（端口 3306 监听中）
  exit /b 0
)
echo [2/2] 启动 MySQL 8.0.46 ...
start "JUZI MySQL 8.0.46" "C:\Users\13535\.workbuddy\tools\mysql-8.0.46-winx64\bin\mysqld.exe" --defaults-file="C:\Users\13535\.workbuddy\mysql-data\my.ini"
echo 已请求启动，等待数秒后可用（mysqladmin ping 验证）
