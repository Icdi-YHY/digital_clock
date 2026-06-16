module digital_clock(
    input wire clk,             // 系统时钟（建议接入 1Hz 用于计时，若是高频时钟需在外部先分频）
    input wire rst,
    input wire [1:0] key_mode,  // 0:正常运行, 1:设置时间, 2:设置闹钟
    input wire key_add,         // 调整数值的按键
    input wire k3,              // 0:选择调节“时”, 1:选择调节“分”

    output reg [3:0] hour_ten,
    output reg [3:0] hour_one,
    output reg [3:0] min_ten,
    output reg [3:0] min_one,
    output reg [3:0] sec_ten,
    output reg [6:0] sec_one,   // 保持原样，仅秒个位输出七段码
    output reg buzzer
);

localparam S_NORMAL=0, S_SET_TIME=1, S_SET_ALARM=2;

// =========================================================================
// 核心寄存器：全部改为 BCD 码存储（个位和十位拆开），彻底抹除运行时拆分逻辑
// =========================================================================
reg [3:0] s_l, s_h;             // 秒个位(0-9)，秒十位(0-5)
reg [3:0] m_l, m_h;             // 分个位(0-9)，分十位(0-5)
reg [3:0] h_l, h_h;             // 时个位(0-9)，时十位(0-2)

reg [3:0] am_l, am_h;           // 闹钟：分个位，分十位
reg [3:0] ah_l, ah_h;           // 闹钟：时个位，时十位

reg key_prev;
wire ke;
reg blk;
reg alm;

// =========================================================================
// 按键及辅助信号
// =========================================================================
// 按键去抖/消抖边缘检测
always @(posedge clk or posedge rst) begin
    if(rst) key_prev <= 1'b0;
    else key_prev <= key_add;
end
assign ke = (key_add && !key_prev); // 调整为标准的上升沿触发

// 闪烁信号 (若 clk 为 1Hz，则每秒翻转一次)
always @(posedge clk or posedge rst) begin
    if(rst) blk <= 1'b0;
    else blk <= ~blk;
end

// 蜂鸣器驱动：只要闹钟标志 alm 为 1，且处于正常走时模式，就直接输出高电平响铃
always @(posedge clk or posedge rst) begin
    if(rst) buzzer <= 1'b0;
    else    buzzer <= (alm && (key_mode == S_NORMAL)) ? 1'b1 : 1'b0;
end

// =========================================================================
// 主时序逻辑：计时 + 调整（由于采用 BCD 架构，所有逻辑变为纯粹的计数器使能）
// =========================================================================
always @(posedge clk or posedge rst) begin
    if(rst) begin
        // 初始时间 12:00:00
        h_h <= 4'd1; h_l <= 4'd2;
        m_h <= 4'd0; m_l <= 4'd0;
        s_h <= 4'd0; s_l <= 4'd0;
        // 初始闹钟 07:00
        ah_h <= 4'd0; ah_l <= 4'd7;
        am_h <= 4'd0; am_l <= 4'd0;
        alm <= 1'b0;
    end else begin
        // 1. 闹钟/整点触发判断（只在进入00秒时触发一次）
        if ((key_mode == S_NORMAL) && 
            (s_h == 4'd0 && s_l == 4'd0) && (!alm)) begin
    
        // 闹钟条件 OR 整点条件（分钟为00）
        if (({h_h, h_l, m_h, m_l} == {ah_h, ah_l, am_h, am_l}) ||
            ({m_h, m_l} == 8'h00)) begin
            alm <= 1'b1; 
        end
        end
        // 2. 报时消除逻辑（响一个周期后自动关闭）
        else if (alm) begin
        // 只响一下：下一个时钟周期立即关闭
            alm <= 1'b0;
        end
        // 2. 按键调整逻辑
        if(ke) begin
            if(key_mode == S_SET_TIME) begin
                if(k3 == 1'b0) begin // 调时
                    if(h_h == 4'd2 && h_l == 4'd3) begin h_h <= 4'd0; h_l <= 4'd0; end
                    else if(h_l == 4'd9)           begin h_l <= 4'd0; h_h <= h_h + 1'b1; end
                    else                           h_l <= h_l + 1'b1;
                end else begin // 调分
                    if(m_h == 4'd5 && m_l == 4'd9) begin m_h <= 4'd0; m_l <= 4'd0; end
                    else if(m_l == 4'd9)           begin m_l <= 4'd0; m_h <= m_h + 1'b1; end
                    else                           m_l <= m_l + 1'b1;
                end
            end else if(key_mode == S_SET_ALARM) begin
                if(k3 == 1'b0) begin // 调闹钟时
                    if(ah_h == 4'd2 && ah_l == 4'd3) begin ah_h <= 4'd0; ah_l <= 4'd0; end
                    else if(ah_l == 4'd9)            begin ah_l <= 4'd0; ah_h <= ah_h + 1'b1; end
                    else                             ah_l <= ah_l + 1'b1;
                end else begin // 调闹钟分
                    if(am_h == 4'd5 && am_l == 4'd9) begin am_h <= 4'd0; am_l <= 4'd0; end
                    else if(am_l == 4'd9)            begin am_l <= 4'd0; am_h <= am_h + 1'b1; end
                    else                             am_l <= am_l + 1'b1;
                end
            end
        end
        // 3. 正常自动计时逻辑 (只有不在设置时间模式下才向前累加)
        else if(key_mode != S_SET_TIME) begin
            if(s_l == 4'd9) begin
                s_l <= 4'd0;
                if(s_h == 4'd5) begin
                    s_h <= 4'd0;
                    if(m_l == 4'd9) begin
                        m_l <= 4'd0;
                        if(m_h == 4'd5) begin
                            m_h <= 4'd0;
                            // 小时进位判断 (23:59:59 -> 00:00:00)
                            if(h_h == 4'd2 && h_l == 4'd3) begin h_h <= 4'd0; h_l <= 4'd0; end
                            else if(h_l == 4'd9)           begin h_l <= 4'd0; h_h <= h_h + 1'b1; end
                            else                           h_l <= h_l + 1'b1;
                        end else m_h <= m_h + 1'b1;
                    end else m_l <= m_l + 1'b1;
                end else s_h <= s_h + 1'b1;
            end else s_l <= s_l + 1'b1;
        end
    end
end

// =========================================================================
// 显示多路选择与输出（纯组合逻辑 MUX，极度节省资源）
// =========================================================================
reg [3:0] dh_h, dh_l;
reg [3:0] dm_h, dm_l;
reg [3:0] ds_h, ds_l;

always @(*) begin
    // 根据当前模式选择送往显示的数据流
    case(key_mode)
        S_SET_TIME: begin
            dh_h = h_h;  dh_l = h_l;
            dm_h = m_h;  dm_l = m_l;
            ds_h = 4'd0; ds_l = 4'd0; // 设置模式下秒清零
        end
        S_SET_ALARM: begin
            dh_h = ah_h; dh_l = ah_l;
            dm_h = am_h; dm_l = am_l;
            ds_h = 4'd0; ds_l = 4'd0;
        end
        default: begin // S_NORMAL
            dh_h = h_h;  dh_l = h_l;
            dm_h = m_h;  dm_l = m_l;
            ds_h = s_h;  ds_l = s_l;
        end
    endcase

    // 最终输出端口赋值与闪烁效果处理
    hour_ten = dh_h;
    
    // 如果在设置模式且当前选中调节“时”(k3==0)，利用 blk 信号让个位显示 0 达到闪烁提示效果
    if((key_mode != S_NORMAL) && (k3 == 1'b0) && blk) hour_one = 4'd0;
    else                                              hour_one = dh_l;

    min_ten = dm_h;
    
    // 如果在设置模式且当前选中调节“分”(k3==1)，利用 blk 信号让个位显示 0 达到闪烁提示效果
    if((key_mode != S_NORMAL) && (k3 == 1'b1) && blk) min_one = 4'd0;
    else                                              min_one = dm_l;

    sec_ten = ds_h;
    sec_one = seg7(ds_l); // 仅在最终输出的一瞬间将秒个位翻译为七段码
end

// =========================================================================
// 七段译码纯组合逻辑函数
// =========================================================================
function [6:0] seg7;
    input [3:0] n;
    begin
        case(n)
            0: seg7=7'b0111111; 1: seg7=7'b0000110;
            2: seg7=7'b1011011; 3: seg7=7'b1001111;
            4: seg7=7'b1100110; 5: seg7=7'b1101101;
            6: seg7=7'b1111101; 7: seg7=7'b0000111;
            8: seg7=7'b1111111; 9: seg7=7'b1101111;
            default: seg7=7'b0000000;
        endcase
    end
endfunction

endmodule