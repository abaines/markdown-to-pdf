// Runs inside a renderer image; started by diagnose-puppeteer.sh.
// Tries launching Puppeteer's browser with different flags, to find what breaks.
const puppeteer = require('/node_modules/puppeteer');

const base = ['--headless', '--no-sandbox', '--disable-gpu', '--disable-setuid-sandbox', '--disable-dev-shm-usage'];
const cases = {
    'as the renderer does (--single-process)': [...base, '--single-process'],
    'without --single-process': base,
};

async function tryLaunch(name, args) {
    const started = Date.now();
    try {
        const browser = await puppeteer.launch({ args, timeout: 15000, dumpio: process.env.DUMPIO === '1' });
        const version = await browser.version();
        await browser.close();
        console.log(`OK    ${name}: ${version} in ${Date.now() - started} ms`);
    } catch (error) {
        console.log(`FAIL  ${name}: ${error.message.split('\n')[0]}`);
    }
}

(async () => {
    for (const [name, args] of Object.entries(cases)) {
        await tryLaunch(name, args);
    }
    process.exit(0);
})();
