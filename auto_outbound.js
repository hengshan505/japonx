/**
 * Surge 自动切换出站模式脚本 - 修正版
 */

// 获取参数中的 SSID
const homeSSID = getArgument('HOME_SSID') || 'GL-MT6000-cb7-5G'; 
const currentSSID = $network.v4.ssid;

console.log(`当前 SSID: ${currentSSID}, 目标 SSID: ${homeSSID}`);

if (currentSSID === homeSSID) {
    // 回家了，切换为直连模式
    $surge.setOutboundMode('direct');
    $notification.post("Surge 自动化", "🏠 已回到家", `自动切换至：直连模式 (SSID: ${currentSSID})`);
} else {
    // 在外面或使用蜂窝网络，切换为规则模式
    $surge.setOutboundMode('rule');
    // 如果您不想每次切蜂窝都弹窗，可以注释掉下面这行
    $notification.post("Surge 自动化", "🚀 已离开家", `自动切换至：规则模式 (SSID: ${currentSSID || '蜂窝网络'})`);
}

$done();

function getArgument(key) {
    if (typeof $argument === 'undefined' || !$argument) return null;
    // 兼容 HOME_SSID=XXX 或直接传入 XXX 的情况
    if (!$argument.includes('=')) return $argument.trim();
    let arg = $argument.split(',').find(a => a.includes(key));
    return arg ? arg.split('=')[1].replace(/\"/g, '').trim() : null;
}
