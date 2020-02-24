const copydir = require('copy-dir');
const path = require('path');
const rimraf = require("rimraf");

const WoW_dir = 'D:\\Games\\BattleNet\\World of Warcraft\\_classic_';
const AddonDir = `${WoW_dir}\\Interface\\Addons\\MonolithDKP_EasyBid`;

rimraf.sync(AddonDir);
copydir.sync(path.join(__dirname, '../src'), AddonDir);