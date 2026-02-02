/**
 * 自动切换出站模式 (多 SSID 支持版)
 * 灵感来自Peng-YM大佬脚本
 * 仅支持Surge
 * 逻辑：匹配列表中任一 Wi-Fi -> 直连；否则 -> 规则
 */

// 1. 获取并处理参数中的多个 SSID
let homeSSIDs = [];
if (typeof $argument !== "undefined" && $argument) {
    let rawArgs = $argument.includes("=") ? $argument.split("=")[1] : $argument;
    // 使用逗号分隔并清理空格
    homeSSIDs = rawArgs.split(",").map(item => item.trim());
}

// 2. 获取当前网络信息
const ssid = $network.wifi.ssid;
const isWiFi = $network.v4.primaryInterface === 'en0';

// 3. 决定目标模式
let targetMode = "rule";
let networkDesc = "蜂窝数据";

if (isWiFi && ssid) {
    networkDesc = `Wi-Fi: ${ssid}`;
    // 检查当前 SSID 是否在我们的直连列表中
    if (homeSSIDs.indexOf(ssid) !== -1) {
        targetMode = "direct";
    }
}

// 4. 执行切换
$surge.setOutboundMode(targetMode);

// 5. 智能通知
const lastNet = $persistentStore.read("last_auto_network");
if (lastNet !== networkDesc) {
    const modeName = { "rule": "🚦规则模式", "direct": "🎯直连模式" }[targetMode];
    $notification.post("🤖 Surge 自动化", `当前网络：${networkDesc}`, `已切换至：${modeName}`);
    $persistentStore.write(networkDesc, "last_auto_network");
}

$done();
