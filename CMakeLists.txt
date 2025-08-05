cmake_minimum_required(VERSION 3.10)
project(MyAsmProject C ASM_NASM)

# 设置 C 标准
set(CMAKE_C_STANDARD 99)

# 启用 NASM 汇编语言支持
enable_language(ASM_NASM)

# 设置 NASM 汇编文件扩展名
set(CMAKE_ASM_NASM_SOURCE_FILE_EXTENSIONS asm)

# 设置 NASM 编译选项（例如启用调试信息）
set(CMAKE_ASM_NASM_FLAGS "-g")

# 自动收集所有 .c 和 .asm 文件
file(GLOB_RECURSE SRC_FILES CONFIGURE_DEPENDS
        ${PROJECT_SOURCE_DIR}/*.c
        ${PROJECT_SOURCE_DIR}/*.asm
)

# 创建可执行文件
add_executable(${PROJECT_NAME} ${SRC_FILES})