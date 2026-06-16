# 工程师 A — 架构与接口工程师

## 职责
模块声明、端口定义、参数定义、结构框架注释、endmodule。

## 负责代码

| 行号 | 代码 |
|------|------|
| 1 | `module digital_clock(` |
| 2 | `input wire clk,` |
| 3 | `input wire rst,` |
| 4 | `input wire [1:0] key_mode,` |
| 5 | `input wire key_add,` |
| 6 | `input wire k3,` |
| 8 | `output reg [3:0] hour_ten,` |
| 9 | `output reg [3:0] hour_one,` |
| 10 | `output reg [3:0] min_ten,` |
| 11 | `output reg [3:0] min_one,` |
| 12 | `output reg [3:0] sec_ten,` |
| 13 | `output reg [6:0] sec_one,` |
| 14 | `output reg buzzer` |
| 15 | `);` |
| 17 | `localparam S_NORMAL=0, S_SET_TIME=1, S_SET_ALARM=2;` |
| 18-20 | 架构注释（BCD 设计说明） |
| 192 | `endmodule` |

## 工作量
- **行数**: ~17 行
- **占比**: ~11%
- **关键贡献**: 模块接口定义、状态机参数、顶层框架
