const fs = require('fs');
const copydir = require('copy-dir');
const path = require('path');
const rimraf = require("rimraf");
const archiver = require('archiver');

const versionTag = "## Version:";
const monDkpVersionTag = "## X-MonolithDKPVersion:";

const srcDir = path.join(__dirname, '../src');
const libDir = path.join(__dirname, '../Libs');
const targetDir = path.join(__dirname, '../target');
const WoW_dir = 'D:\\Games\\BattleNet\\World of Warcraft\\_classic_';
const AddonDir = `${WoW_dir}\\Interface\\Addons\\MonolithDKP_EasyBid`;

const copySources = (dest) => {
    copydir.sync(srcDir, dest);
    copydir.sync(libDir, `${dest}\\Libs`);
};

const getVersions = () => {
    const contents = fs.readFileSync(path.join(srcDir, 'MonolithDKP_EasyBid.toc'), 'utf8');
    const lines = contents.split(/(?:\r\n|\r|\n)/g);
    const result = [ null, null ];

    for (let i = 0; i < lines.length; i++) {
        if (lines[i].startsWith(versionTag)) {
            result[0] = lines[i].substring(versionTag.length).trim();
        } else if (lines[i].startsWith(monDkpVersionTag)) {
            result[1] = lines[i].substring(monDkpVersionTag.length).trim();
        }
    }

    return result;
};

const createZip = (dir, target) => {
    const output = fs.createWriteStream(target);
    const archive = archiver('zip', {
        zlib: { level: 9 } // Sets the compression level.
    });

    output.on('close', function() {
        console.log(archive.pointer() + ' total bytes');
        console.log('archiver has been finalized and the output file descriptor has closed.');
    });

    output.on('end', function() {
        console.log('Data has been drained');
    });

    archive.on('warning', function(err) {
        if (err.code === 'ENOENT') {
            console.warn(err);
        } else {
            throw err;
        }
    });

    archive.on('error', function(err) {
        throw err;
    });

    archive.pipe(output);
    archive.directory(dir, 'MonolithDKP_EasyBid');
    archive.finalize();
};


rimraf.sync(targetDir);
if (!fs.existsSync(targetDir)){
    fs.mkdirSync(targetDir);
}
copySources(path.join(targetDir, 'sources'));

const versions = getVersions();
createZip(path.join(targetDir, 'sources'), path.join(targetDir, `MonolithDKP_EasyBid-v${versions[0]}-v${versions[1]}.zip`));

rimraf.sync(AddonDir);
copySources(AddonDir);

