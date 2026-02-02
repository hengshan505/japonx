/**
 * 自动切换出站模式 (参考 Peng-YM 稳健版)
 * 逻辑：蜂窝->规则；指定WiFi->直连；其他WiFi->规则
 */

// --- 配置区域 ---
const CONFIG = {
  home_wifi: "GL-MT6000-cb7-5G", // 您家的 WiFi
  cellular_mode: "rule",         // 蜂窝网模式
  wifi_default_mode: "rule",     // 其他 WiFi 默认模式
  home_mode: "direct"            // 家里 WiFi 模式
};

const ssid = $network.wifi.ssid; // 获取当前 WiFi 名称
let targetMode = ssid ? (ssid === CONFIG.home_wifi ? CONFIG.home_mode : CONFIG.wifi_default_mode) : CONFIG.cellular_mode;

// 执行切换
$surge.setOutboundMode(targetMode);

// 智能通知（通过持久化存储记录上次状态，避免重复弹窗）
const lastSSID = $persistentStore.read("last_network_ssid");
const currentNetwork = ssid ? `Wi-Fi: ${ssid}` : "蜂窝数据";

if (lastSSID !== currentNetwork) {
    const modeName = { "rule": "🚦规则模式", "direct": "🎯直连模式", "global-proxy": "🚀全局模式" }[targetMode];
    $notification.post("🤖 Surge 运行模式", `当前网络：${currentNetwork}`, `已自动切换至：${modeName}`);
    $persistentStore.write(currentNetwork, "last_network_ssid");
}

$done();
