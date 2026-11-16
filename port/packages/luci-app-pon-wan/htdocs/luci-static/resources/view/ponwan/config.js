// SPDX-License-Identifier: GPL-2.0-only
//
// PON WAN service VLAN for the TYFZA1 (Realtek RTL9617CVW).
//
// pon0 is the PON uplink created by board.d/02_network as the wan device, and
// it is a plain netdev rather than a DSA switch, so the operator service VLAN
// has to become a netifd 802.1q device named pon0.<vid>.

'use strict';
'require form';
'require network';
'require uci';
'require view';

function validateIfname(sectionId, value) {
	if (!/^[A-Za-z0-9_.:-]{1,15}$/.test(value || ''))
		return '设备名只能使用字母、数字和 _ . : -，且不超过 15 个字符。';

	return true;
}

function validateVlan(sectionId, value) {
	if (!/^[0-9]{1,4}$/.test(value || ''))
		return '业务 VLAN 必须是数字。';

	var vid = parseInt(value, 10);

	if (vid < 1 || vid > 4094)
		return '业务 VLAN 必须在 1 到 4094 之间。';

	return true;
}

var PON_MODES = {
	gpon: 'GPON',
	xgpon: 'XGS-PON',
	xgspon: 'XGS-PON',
	epon: 'EPON'
};

return view.extend({
	load: function() {
		return Promise.all([
			uci.load('pon_wan'),
			uci.load('pon'),
			network.getDevices()
		]);
	},

	render: function(data) {
		var ponDevices = (data[2] || []).filter(function(device) {
			return /^pon[0-9]+$/.test(device.getName());
		}).map(function(device) {
			return device.getName();
		}).sort();

		var ponEnabled = uci.get('pon', 'pon', 'enabled');
		var ponMode = uci.get('pon', 'pon', 'mode');
		var wanDevice = uci.get('network', 'wan', 'device');
		var uplinkConfigured = uci.get('pon_wan', 'settings', 'uplink') || 'pon0';

		var ponState = (ponEnabled === '0') ? 'PON 服务已禁用'
			: (PON_MODES[ponMode] ? 'PON 服务已启用（' + PON_MODES[ponMode] + '）'
				: 'PON 服务已启用（模式未写入配置，由出厂参数决定）');

		var hint = '当前 WAN 设备：' + (wanDevice || '未配置') + '。';

		if (ponDevices.length === 0)
			hint += ' 未发现 pon* 设备，PON 驱动可能未加载，此时启用 VLAN 绑定不会生效。';

		var m, s, o;

		m = new form.Map('pon_wan', 'PON WAN 业务 VLAN',
			'把运营商的业务 VLAN 绑定到 PON 口，生成 ' + uplinkConfigured + '.VLAN 形式的 802.1q 设备，'
			+ '并把接口挂进 wan 防火墙区域。' + ponState + '。' + hint);

		m.readonly = !L.hasViewPermission();

		s = m.section(form.NamedSection, 'settings', 'pon_wan');
		s.anonymous = true;
		s.addremove = false;

		o = s.option(form.Flag, 'enabled', '启用');
		o.default = '0';
		o.rmempty = false;
		o.description = '关闭时恢复 PON 口原始绑定；只还原本页创建过的 VLAN 绑定。';

		o = s.option(form.ListValue, 'uplink', 'PON 设备',
			'承载业务流量的 PON 口。本机默认是 pon0。');
		o.default = 'pon0';
		o.rmempty = false;
		ponDevices.forEach(function(name) {
			o.value(name);
		});
		if (ponDevices.indexOf('pon0') < 0)
			o.value('pon0');
		o.depends('enabled', '1');

		o = s.option(form.Value, 'vlan', '业务 VLAN / LAN ID',
			'运营商在 PON 口上标记的业务 VLAN。IP 不认证的地区通常为空或 41，需以当地 OLT 下发的为准。');
		o.placeholder = '41';
		o.rmempty = false;
		o.validate = validateVlan;
		o.depends('enabled', '1');

		o = s.option(form.Value, 'iface', '网络接口',
			'绑定到 VLAN 设备的接口，保持原有名称可继续使用 wan 区域的 NAT 与转发规则。');
		o.default = 'wan';
		o.rmempty = false;
		o.validate = validateIfname;
		o.depends('enabled', '1');

		o = s.option(form.ListValue, 'proto', '协议');
		o.default = 'dhcp';
		o.rmempty = false;
		o.value('dhcp', 'DHCP 客户端');
		o.value('pppoe', 'PPPoE 拨号');
		o.value('static', '静态地址');
		o.value('none', '不配置协议');
		o.depends('enabled', '1');

		o = s.option(form.Value, 'ipaddr', 'IPv4 地址');
		o.rmempty = true;
		o.depends('enabled', '1');
		o.depends('proto', 'static');

		o = s.option(form.Value, 'netmask', 'IPv4 子网掩码');
		o.default = '255.255.255.0';
		o.rmempty = false;
		o.depends('enabled', '1');
		o.depends('proto', 'static');

		o = s.option(form.Value, 'gateway', 'IPv4 网关');
		o.rmempty = true;
		o.depends('enabled', '1');
		o.depends('proto', 'static');

		o = s.option(form.Value, 'dns', 'DNS 服务器');
		o.placeholder = '223.5.5.5';
		o.rmempty = true;
		o.depends('enabled', '1');
		o.depends('proto', 'static');

		o = s.option(form.Value, 'pppoe_username', 'PPPoE 用户名');
		o.rmempty = true;
		o.depends('enabled', '1');
		o.depends('proto', 'pppoe');

		o = s.option(form.Value, 'pppoe_password', 'PPPoE 密码');
		o.password = true;
		o.rmempty = true;
		o.depends('enabled', '1');
		o.depends('proto', 'pppoe');

		return m.render();
	}
});