/**
 * Surge 自动切换出站模式脚本
 * 功能：连接指定 Wi-Fi 时切换为直连，离开时恢复规则模式。
 * 参数：在 [Script] 中通过 argument 传入 HOME_SSID="你的WiFi"
 */

const homeSSID = getArgument('HOME_SSID') || 'Your_Home_WiFi_Name'; // 默认值
const currentSSID = $network.v4.ssid;

if (currentSSID === homeSSID) {
    // 回家了，切换为直连模式
    if ($surge.setOutboundMode('direct')) {
        $notification.post("Surge 自动化", "🏠 已回到家", "自动切换至：直连模式 (Direct)");
    }
} else {
    // 在外面或使用蜂窝网络，切换为规则模式
    if ($surge.setOutboundMode('rule')) {
        $notification.post("Surge 自动化", "🚀 已离开家", "自动切换至：规则模式 (Rule)");
    }
}

$done();

function getArgument(key) {
    if (typeof $argument === 'undefined' || !$argument) return null;
    let arg = $argument.split(',').find(a => a.includes(key));
    return arg ? arg.split('=')[1].replace(/\"/g, '') : null;
}
