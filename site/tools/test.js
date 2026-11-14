const { chromium } = require('playwright');
const path = require('path');
const dist = path.resolve(process.argv[2]);
(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1366, height: 900 } });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(page.url().split('/').pop() + ': ' + m.text()); });
  page.on('pageerror', e => errors.push(page.url().split('/').pop() + ': ' + e.message));
  const open = async (f) => { await page.goto('file://' + path.join(dist, f)); await page.waitForTimeout(400); };
  const text = async (sel) => (await page.locator(sel).first().textContent() || '').trim();

  const pages = ['index.html','werkgevers.html','gemeenten.html','aanpak.html','over-ons.html','contact.html','inloggen.html','portaal.html'];
  for (const f of pages) {
    await open(f);
    const h1 = await text('h1');
    const links = await page.locator('a[href$=".html"]').count();
    const overflow = await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1);
    console.log(f.padEnd(16), 'h1:', h1.slice(0, 40).padEnd(42), 'links:', links, overflow ? 'HORIZONTAL OVERFLOW' : '');
  }

  // navigatie via kop
  await open('index.html');
  await page.click('nav[aria-label="Hoofdmenu"] a:has-text("Werkgevers")');
  await page.waitForTimeout(300);
  console.log('nav ->', page.url().split('/').pop());

  // werkgevers: situatiekiezer
  await page.click('[role=tablist] button:has-text("Misverstanden")');
  await page.waitForTimeout(200);
  console.log('tab ->', (await text('.l-panel h3')).slice(0, 50));

  // gemeenten: fase + indicator
  await open('gemeenten.html');
  await page.click('[role=tablist] .l-fase:has-text("Nazorg")');
  await page.waitForTimeout(200);
  console.log('fase ->', await text('.l-panel .l-label'));
  const before = await page.locator('figure dl > div').count();
  await page.locator('label.l-toggle').last().click();
  await page.waitForTimeout(200);
  console.log('indicatoren', before, '->', await page.locator('figure dl > div').count());

  // aanpak: lijn
  await open('aanpak.html');
  await page.click('button:has-text("Volgende stap")');
  await page.waitForTimeout(200);
  console.log('aanpak stap ->', await text('.l-panel .l-label'));

  // contact: validatie en invullen
  await open('contact.html');
  await page.click('button[type=submit]');
  await page.waitForTimeout(200);
  console.log('contact leeg ->', (await text('[role=alert] p')).slice(0, 60));
  await page.click('label.l-choice:has-text("Ik ben werkgever")');
  await page.fill('#veld-naam', 'Test Persoon');
  await page.fill('#veld-email', 'test@voorbeeld.nl');
  await page.fill('#veld-tekst', 'Korte toelichting voor de demo.');
  console.log('focus behouden:', await page.evaluate(() => document.activeElement && document.activeElement.id), '| pct:', await text('.l-label + .l-label'));
  await page.click('button[type=submit]');
  await page.waitForTimeout(200);
  console.log('contact ok ->', await text('[role=status] h2'));

  // inloggen: matrix
  await open('inloggen.html');
  await page.click('.l-role:has-text("Gemeente")');
  await page.waitForTimeout(200);
  console.log('matrix ->', (await page.locator('div.l-rv .l-label').last().textContent()));

  // portaal: volledige stroom
  await open('portaal.html');
  console.log('portaal rol ->', await text('.p-seg button[aria-pressed=true]'));
  await page.click('.p-row.sel:has-text("Samira")');
  await page.waitForTimeout(200);
  console.log('traject ->', await text('.p-h1'));
  await page.click('button:has-text("+ Leerdoel")');
  await page.fill('#g-titel', 'Pauzes aankondigen bij de teamleider');
  await page.click('button:has-text("Leerdoel opslaan")');
  await page.waitForTimeout(300);
  console.log('toast ->', (await text('.p-toast span')).slice(0, 70));
  await page.click('button:has-text("+ Afspraak")');
  await page.fill('#a-titel', 'Werkplekbezoek 2');
  await page.fill('#a-datum', '2026-11-03');
  await page.fill('#a-tijd', '10:00');
  await page.selectOption('#a-task', 'o5');
  await page.check('#a-task ~ *, input[type=checkbox] >> nth=2').catch(() => {});
  await page.click('button:has-text("Afspraak opslaan")');
  await page.waitForTimeout(300);
  console.log('toast ->', (await text('.p-toast span')).slice(0, 90));
  // naar deelnemer
  await page.click('.p-seg button:has-text("Deelnemer")');
  await page.waitForTimeout(200);
  console.log('deelnemer volgende opdracht ->', await text('#d-next-task ~ p'));
  await page.click('button:has-text("Opdracht maken")');
  await page.fill('#ans', 'STOP: bij het bord bij de heftruck. Ik stop en wacht.');
  await page.click('button:has-text("Opdracht inleveren")');
  await page.waitForTimeout(300);
  console.log('toast ->', (await text('.p-toast span')).slice(0, 60));
  // begeleider feedback
  await page.click('.p-seg button:has-text("Begeleider")');
  await page.waitForTimeout(200);
  const todo = await page.locator('#b-todo ~ ul .p-row').count();
  console.log('wacht op mij:', todo);
  await page.click('#b-todo ~ ul button:has-text("Feedback geven") >> nth=0');
  await page.fill('#fb', 'Goed gedaan, duidelijke zinnen.');
  await page.click('label.p-check:has-text("Lukt met hulp")');
  await page.click('button:has-text("Feedback versturen")');
  await page.waitForTimeout(300);
  console.log('toast ->', (await text('.p-toast span')).slice(0, 80));
  // werkgever ziet alleen gedeelde
  await page.click('.p-seg button:has-text("Werkgever")');
  await page.waitForTimeout(200);
  console.log('werkgever ziet notities?', await page.locator('text=Interne notities').count(), '| gedeelde afspraken:', await page.locator('.p-pill:has-text("Gedeeld met u")').count());
  await page.click('.p-seg button:has-text("Gemeente")');
  await page.waitForTimeout(200);
  console.log('gemeente kaarten:', await page.locator('main section.p-card').count());

  await page.setViewportSize({ width: 390, height: 844 });
  await open('index.html');
  console.log('mobiel overflow:', await page.evaluate(() => document.documentElement.scrollWidth > document.documentElement.clientWidth + 1));
  await page.screenshot({ path: path.join(dist, '..', 'shot-mobile.png'), fullPage: false });
  await page.setViewportSize({ width: 1366, height: 900 });
  await open('index.html');
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(dist, '..', 'shot-home.png') });
  await open('portaal.html');
  await page.screenshot({ path: path.join(dist, '..', 'shot-portaal.png') });

  console.log('\nconsolefouten:', errors.length);
  errors.slice(0, 10).forEach(e => console.log('  ', e.slice(0, 160)));
  await browser.close();
})().catch(e => { console.error('TESTFOUT', e.message); process.exit(1); });
