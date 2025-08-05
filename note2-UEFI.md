UEFI（统一可扩展固件接口）启动过程从系统加电开始，经历多个阶段，最终将控制权交给操作系统。下面是从 **SEC（Security）阶段到 Runtime（RT）阶段** 的详细流程解析：

---

## 🚀 UEFI启动七阶段概览

| 阶段 | 名称 | 主要任务 |
|------|------|----------|
| 1️⃣ | SEC（Security） | 初始化CPU、设置临时内存、建立可信根 |
| 2️⃣ | PEI（Pre-EFI Initialization） | 初始化内存、构建HOB列表、准备DXE环境 |
| 3️⃣ | DXE（Driver Execution Environment） | 加载驱动、初始化硬件、构建系统服务 |
| 4️⃣ | BDS（Boot Device Selection） | 加载启动项、准备操作系统加载 |
| 5️⃣ | TSL（Transient System Load） | 加载OS Loader（如GRUB） |
| 6️⃣ | RT（Runtime） | 操作系统接管，保留UEFI运行时服务 |
| 7️⃣ | AL（After Life） | 灾难恢复或关机处理（非标准定义） |

---

## 🔐 SEC阶段（Security /CPU厂商提供）

- **启动入口**：系统加电后，CPU从复位向量（Reset Vector）开始执行。
- **实模式转保护模式**：将CPU从16位实模式切换到32位或64位平坦模式。
- **初始化临时RAM**：使用 CPU 的 Cache 作为临时内存（CAR技术）。
- **建立中断描述符表（IDT）**：处理异常和中断。
- **传递控制权**：构造 `EFI_SEC_PEI_HAND_OFF` 结构体，传递给 PEI 阶段。

---

## 🧩 PEI阶段（Pre-EFI Initialization /CPU和主板厂商提供）

- **初始化内存控制器**：真正的内存开始可用。
- **加载PEIM模块**：通过 PEI Dispatcher 调度各个 PEIM（模块化设计）。
- **构建HOB列表**：Hand-Off Blocks 用于传递系统状态和资源信息给 DXE。
- **启动DXE IPL**：调用 DXE Initial Program Loader，进入 DXE 阶段。

---

## 🛠️ DXE阶段（Driver Execution Environment IO设备厂商提供）

- **加载DXE核心**：初始化 Boot Services、Runtime Services。
- **驱动调度**：DXE Dispatcher 加载并执行所有驱动。
- **构建EFI系统表**：包括 Console、Configuration Table 等。
- **准备启动设备**：控制权交给 BDS 阶段。

---

## 🧭 BDS阶段（Boot Device Selection）

- **初始化控制台设备**：如键盘、显示器。
- **加载启动项**：如 GRUB、Windows Boot Manager。
- **用户交互**：提供 BIOS Setup 界面、启动选项选择。

---

## 🧬 TSL阶段（Transient System Load/运行厂商efi文件,通常为bootx64.efi或者bootia32.efi）

- **加载OS Loader**：如 GRUB 加载 Linux 内核/。
- **调用 ExitBootServices()**：释放UEFI控制权，进入操作系统。

---

## 🧠 RT阶段（Runtime ）

- **操作系统接管**：UEFI只保留 Runtime Services（如时间服务、变量访问）。
- **MM模式运行**：UEFI运行时服务在独立内存空间中运行，避免与OS冲突。

---

## UEFI 底层服务
### BootService
- 服务TSL阶段，
- 让loader （如grub）获取部分数据后加载OS
- 作为中间桥梁，在BootService结束前，取出OS启动需要的数据
- grub可以同时使用到BootService和RuntimeService

### RuntimeService
- 在UEFI整个生命周期

- 提供服务很少
