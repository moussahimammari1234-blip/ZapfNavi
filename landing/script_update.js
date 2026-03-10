const fs = require('fs');
const indexPath = 'index.html';
const stylePath = 'styles.css';
const i18nPath = 'i18n.js';
const impressumPath = 'impressum.html';

// 1. Update CSS
let css = fs.readFileSync(stylePath, 'utf8');

// Replace floating cards CSS
const oldFloatCards = `.fc-left{top:18%;left:-12%}
.fc-right{bottom:16%;right:-14%;animation-delay:1.5s}
@keyframes float-card{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}`;

const newFloatCards = `.fc-left{top:20%;left:-5%}
.fc-right{bottom:20%;right:-5%;animation-delay:1.5s}
@keyframes float-card{0%,100%{transform:translateY(0)}50%{transform:translateY(-10px)}}`;

css = css.replace(oldFloatCards, newFloatCards);

// Replace mobile view for hero and float cards
const oldHeroMobile = `@media(max-width:960px){.hero{flex-direction:column;text-align:center;padding-top:140px}.hero-text{align-items:center;display:flex;flex-direction:column}.hero .sub{margin-left:auto;margin-right:auto}.hero-visual{margin-top:30px}.float-card{display:none}.store-badges{justify-content:center!important}.hero-social{justify-content:center}}`;
const newHeroMobile = `@media(max-width:960px){.hero{flex-direction:column;text-align:center;padding-top:140px;overflow:hidden}.hero-text{align-items:center;display:flex;flex-direction:column}.hero .sub{margin-left:auto;margin-right:auto}.hero-visual{margin-top:30px;width:100%}.store-badges{justify-content:center!important}.hero-social{justify-content:center}.fc-left{top:5%;left:5%;transform:scale(0.8)}.fc-right{bottom:5%;right:5%;transform:scale(0.8)}}@media(max-width:500px){.fc-left{top:0;left:-5%;transform:scale(0.7)}.fc-right{bottom:0;right:-5%;transform:scale(0.7)}}`;
css = css.replace(oldHeroMobile, newHeroMobile);

// Change font
css = css.replace(/font-family:'Inter',system-ui,sans-serif/g, "font-family:'Inter',system-ui,sans-serif");
css += `\nh1, h2, h3, h4, h5, .nav-logo, .btn-nav, .sec-label, .price-amount { font-family: 'Outfit', system-ui, sans-serif; }`;

fs.writeFileSync(stylePath, css);

// 2. Update HTML
let html = fs.readFileSync(indexPath, 'utf8');
// add outfit font
html = html.replace('100;400;500;600;700;800;900&display=swap"', '100;400;500;600;700;800;900&family=Outfit:wght@400;600;700;800;900&display=swap"');

// replace pricing section HTML
const oldPricing = `<div class="pricing-wrap">
                <div class="price-card">
                    <span class="price-tag" data-i18n="plan1_tag">NACH DER TESTPHASE</span>
                    <div class="price-amount" data-i18n="plan1_price">0€</div>
                    <p class="price-desc" data-i18n="plan1_desc">Weiter kostenlos nutzen — mit Werbung</p>
                    <ul class="price-features">
                        <li data-i18n="plan1_f1">Alle Tankstellen & Preise</li>
                        <li data-i18n="plan1_f2">GPS-Suche & Navigation</li>
                        <li data-i18n="plan1_f3">Preisalarm & Favoriten</li>
                        <li data-i18n="plan1_f4">Mit Werbeanzeigen</li>
                    </ul>
                    <button class="btn-price btn-price-outline" data-i18n="plan1_btn">Kostenlos starten</button>
                </div>
                <div class="price-card featured">
                    <span class="price-tag" data-i18n="plan2_tag">PREMIUM — WERBEFREI</span>
                    <div class="price-amount">2,99€ <small data-i18n="plan2_period">/ Monat</small></div>
                    <p class="price-desc" data-i18n="plan2_desc">Komplett ohne Werbung — jederzeit kündbar</p>
                    <ul class="price-features">
                        <li data-i18n="plan2_f1">Alle Features inklusive</li>
                        <li data-i18n="plan2_f2">Keine Werbung — null Ablenkung</li>
                        <li data-i18n="plan2_f3">Prioritäts-Support</li>
                        <li data-i18n="plan2_f4">Jederzeit kündbar</li>
                    </ul>
                    <button class="btn-price btn-price-primary" data-i18n="plan2_btn">Premium starten</button>
                </div>
            </div>`;

const newPricing = `<div class="pricing-wrap" style="max-width:600px;margin:50px auto 0;">
                <div class="price-card featured" style="max-width:100%;">
                    <span class="price-tag" data-i18n="plan2_tag">FÜR UNSERE SERVER</span>
                    <div class="price-amount">2,99€ <small data-i18n="plan2_period">/ Monat</small></div>
                    <p class="price-desc" data-i18n="plan2_desc" style="font-size:16px;">ZapfNavi bleibt fair. Wir finanzieren damit lediglich unsere Serverkosten, damit das System live und extrem schnell bleibt.</p>
                    <ul class="price-features" style="max-width:300px;margin:20px auto 30px;">
                        <li data-i18n="plan2_f2">Null nervige Werbung</li>
                        <li data-i18n="plan1_f1">Alle Live-Preise für immer</li>
                        <li data-i18n="plan2_f3">Höchste Genauigkeit</li>
                        <li data-i18n="plan2_f4">Einfach kündbar</li>
                    </ul>
                    <button class="btn-price btn-price-primary" data-i18n="plan2_btn">App herunterladen</button>
                </div>
            </div>`;

html = html.replace(oldPricing, newPricing);

// update links mapping function in html
const oldRenderBadges = `function renderBadges(containerId) {
            const c = document.getElementById(containerId);
            if (!c) return;
            c.innerHTML = [
                { s: badgeSVGs.play, name: 'Google Play' },
                { s: badgeSVGs.apple, name: 'App Store' },
                { s: badgeSVGs.galaxy, name: 'Galaxy Store' },
                { s: badgeSVGs.huawei, name: 'AppGallery' }
            ].map(b => \`<a href="#download" class="badge-btn">\${b.s}<div><span class="b-name">\${b.name}</span></div></a>\`).join('');
        }`;

const newRenderBadges = `function renderBadges(containerId) {
            const c = document.getElementById(containerId);
            if (!c) return;
            c.innerHTML = [
                { s: badgeSVGs.play, name: 'Google Play', url: 'https://play.google.com/store/apps' },
                { s: badgeSVGs.apple, name: 'App Store', url: 'https://www.apple.com/app-store/' },
                { s: badgeSVGs.galaxy, name: 'Galaxy Store', url: 'https://galaxystore.samsung.com/' },
                { s: badgeSVGs.huawei, name: 'AppGallery', url: 'https://appgallery.huawei.com/' }
            ].map(b => \`<a href="\${b.url}" target="_blank" rel="noopener noreferrer" class="badge-btn">\${b.s}<div><span class="b-name">\${b.name}</span></div></a>\`).join('');
        }`;

html = html.replace(oldRenderBadges, newRenderBadges);
fs.writeFileSync(indexPath, html);


// 3. Update Impressum
const imp = \`<!DOCTYPE html>
<html lang="de" dir="ltr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>ZapfNavi - Impressum & Kontakt</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;600;800&family=Inter:wght@400;500;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Inter', sans-serif; background: #050508; color: #fff; line-height: 1.6; padding: 40px 20px; }
        .container { max-width: 800px; margin: 0 auto; background: rgba(18,18,26,0.65); padding: 40px; border-radius: 20px; border: 1px solid rgba(255,255,255,0.1); }
        h1, h2 { font-family: 'Outfit', sans-serif; color: #FF5E00; margin-bottom: 20px; }
        a { color: #FFC837; text-decoration: none; }
        a:hover { text-decoration: underline; }
        p { margin-bottom: 20px; color: #a0aec0; }
        .back { display: inline-block; margin-bottom: 30px; padding: 10px 20px; background: #FF5E00; color: #fff; border-radius: 50px; text-decoration: none; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <a href="index.html" class="back">← Zurück zur Startseite</a>
        <h1>Impressum & Kontakt</h1>
        <h2>Angaben gemäß § 5 TMG</h2>
        <p>
            Moussahim Ammari<br>
            Entwickler ZapfNavi<br>
            Bayreuth, Deutschland
        </p>

        <h2>Kontakt</h2>
        <p>Wir freuen uns immer über dein Feedback! Bei Fragen, Kritik oder Anregungen erreichst du uns jederzeit und ganz unkompliziert per E-Mail:</p>
        <p><strong>E-Mail:</strong> <a href="mailto:support@zapfnavi.de">support@zapfnavi.de</a></p>
    </div>
</body>
</html>\`;
fs.writeFileSync(impressumPath, imp);


// 4. Update i18n
let i18n = fs.readFileSync(i18nPath, 'utf8');

// replace some texts in DE
i18n = i18n.replace('"hero_title": "Stopp die Abzocke! Spare bis zu <span class=\\"hl\\">7€</span> pro Tankfüllung."', '"hero_title": "Mach Schluss mit teurem Sprit! Spare <span class=\\"hl\\">7€</span> pro Tankfüllung."');
i18n = i18n.replace('"hero_sub": "Spritpreise explodieren. Mit ZapfNavi drehst du den Spieß um! Finde sofort den günstigsten Preis, nutze Preisalarme und spare hunderte Euro im Jahr."', '"hero_sub": "Vergiss die explodierenden Spritpreise. Mit ZapfNavi hast du die volle Kontrolle! Finde blitzschnell die günstigste Tankstelle, lass dich vom Preisalarm warnen und behalte dein Geld für dich."');
i18n = i18n.replace('"price_title": "Transparent, Fair & Ohne Falle"', '"price_title": "Keine Abofalle, nur ein fairer Beitrag"');
i18n = i18n.replace('"price_trial": "🎉 <b>Wir sind sicher, dass du sparst.</b> Daher schenken wir dir die ersten 2 Tage!"', '"price_trial": "🎉 <b>Lade die App jetzt herunter</b> und starte sofort mit dem Sparen!"');

fs.writeFileSync(i18nPath, i18n);
console.log("Done");
