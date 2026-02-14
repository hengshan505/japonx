/*
* Loon WiFi 自动切换流量模式脚本
* 功能：
* - 根据当前 WiFi 名称（SSID）切换所有策略组到 RULE / PROXY / DIRECT
* - 从 RULE 切到全局时会保存原策略；回到 RULE 时自动恢复
* 触发：
* - network-changed
*/

let config = {
// 你的“全局代理”与“全局直连”策略名（必须是你配置里真实存在的策略组/策略名）
global_proxy: "自动选择",
global_direct: "全球直连",

// 默认模式
cellular: "RULE", // 蜂窝网络默认模式: RULE / PROXY / DIRECT
wifi_default: "RULE", // WiFi未命中名单时默认模式

// 指定 WiFi 名称列表
all_proxy_ssid: ["CompanyWiFi", "Office-5G"], // 命中后走全局代理
all_direct_ssid: ["HomeWiFi", "GL-MT6000-cb7-5G"], // 命中后走全局直连

// 是否静默
silence: false,
};

const KEY_MODE = "loon_wifi_mode_current";
const KEY_DECISIONS = "loon_wifi_mode_saved_decisions";

main()
.catch((e) => {
notify("📶 WiFi模式切换", "执行失败", String(e));
console.log("[wifi-mode-switch] ERROR:", e);
})
.finally(() => $done());

async function main() {
const conf = JSON.parse($config.getConfig());
const allGroups = conf.all_policy_groups || [];
const currentSSID = conf.ssid || "";
const prevMode = $persistentStore.read(KEY_MODE) || "RULE";

const targetMode = currentSSID ? getSSIDMode(currentSSID) : config.cellular;

console.log(`[wifi-mode-switch] SSID=${currentSSID || "cellular"}, ${prevMode} -> ${targetMode}`);

if (prevMode === targetMode) {
if (!config.silence) notify("📶 WiFi模式切换", `当前网络：${currentSSID || "蜂窝数据"}`, `保持${modeText(targetMode)}`);
return;
}

if (prevMode === "RULE" && targetMode !== "RULE") {
saveCurrentDecisions(conf.policy_select || {}, allGroups);
applyGlobalMode(allGroups, targetMode);
} else if (prevMode !== "RULE" && targetMode === "RULE") {
restoreDecisions(allGroups);
} else {
// PROXY <-> DIRECT
applyGlobalMode(allGroups, targetMode);
}

$persistentStore.write(targetMode, KEY_MODE);

if (!config.silence) {
notify(
"📶 WiFi模式切换",
`当前网络：${currentSSID || "蜂窝数据"}`,
`已切换到 ${modeText(targetMode)}`
);
}
}

function applyGlobalMode(groups, mode) {
const targetPolicy = mode === "PROXY" ? config.global_proxy : config.global_direct;

for (const g of groups) {
if (config.whitelist_groups.includes(g)) continue;
try {
$config.setSelectPolicy(g, targetPolicy);
console.log(`[wifi-mode-switch] ${g} => ${targetPolicy}`);
} catch (e) {
console.log(`[wifi-mode-switch] skip ${g}: ${e}`);
}
}
}

function saveCurrentDecisions(decisions, groups) {
const filtered = {};
for (const g of groups) {
if (decisions[g]) filtered[g] = decisions[g];
}
$persistentStore.write(JSON.stringify(filtered), KEY_DECISIONS);
console.log("[wifi-mode-switch] decisions saved");
}

function restoreDecisions(groups) {
const raw = $persistentStore.read(KEY_DECISIONS);
if (!raw) {
console.log("[wifi-mode-switch] no saved decisions");
return;
}
const decisions = JSON.parse(raw);
for (const g of groups) {
if (!decisions[g]) continue;
try {
$config.setSelectPolicy(g, decisions[g]);
console.log(`[wifi-mode-switch] restore ${g} => ${decisions[g]}`);
} catch (e) {
console.log(`[wifi-mode-switch] restore skip ${g}: ${e}`);
}
}
}

function getSSIDMode(ssid) {
if (config.all_direct_ssid.includes(ssid)) return "DIRECT";
if (config.all_proxy_ssid.includes(ssid)) return "PROXY";
return config.wifi_default;
}

function modeText(mode) {
return { RULE: "规则模式", PROXY: "全局代理", DIRECT: "全局直连" }[mode] || mode;
}

function notify(title, subtitle, body) {
$notification.post(title, subtitle, body);
}
