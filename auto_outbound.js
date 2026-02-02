/**
 * 自动切换出站模式 (通用参数版)
 * 逻辑：蜂窝/其他WiFi -> 规则模式；指定参数WiFi -> 直连模式
 */

// 1. 获取模块传来的 WiFi 名称参数
let homeSSID = "";
if (typeof $argument !== "undefined" && $argument) {
    // 支持 argument=HOME_SSID=XXXX 或直接 argument=XXXX
    homeSSID = $argument.includes("=") ? $argument.split("=")[1].trim() : $argument.trim();
}

// 2. 获取当前网络信息
const ssid = $network.wifi.ssid;
const isWiFi = $network.v4.primaryInterface === 'en0';

// 3. 决定目标模式
let targetMode = "rule"; // 默认规则模式
let networkDesc = "蜂窝数据";

if (isWiFi && ssid) {
    networkDesc = `Wi-Fi: ${ssid}`;
    if (ssid === homeSSID) {
        targetMode = "direct";
    }
}

// 4. 执行切换
$surge.setOutboundMode(targetMode);

// 5. 智能通知 (防止重复弹窗)
const lastNet = $persistentStore.read("last_auto_network");
if (lastNet !== networkDesc) {
    const modeName = { "rule": "🚦规则模式", "direct": "🎯直连模式" }[targetMode];
    $notification.post("🤖 Surge 自动化", `当前网络：${networkDesc}`, `已切换至：${modeName}`);
    $persistentStore.write(networkDesc, "last_auto_network");
}

$done();
