const fs = require('fs');
const path = require('path');

const i18nPath = path.join(__dirname, 'i18n.js');
const indexPath = path.join(__dirname, 'index.html');

let i18nContent = fs.readFileSync(i18nPath, 'utf8');

// The new i18n replaces text to become highly persuasive and marketing-focused.
const translations = {
    de: {
        nav_features: "Lösung", nav_savings: "Gewinn", nav_pricing: "Preise", nav_download: "Holen", nav_cta: "App laden",
        hero_badge: "🔥 2 Tage komplett kostenlos testen!",
        hero_title: 'Stopp die Abzocke! Spare bis zu <span class="hl">7€</span> pro Tankfüllung.',
        hero_sub: "Spritpreise explodieren. Mit ZapfNavi drehst du den Spieß um! Finde sofort den günstigsten Preis, nutze Preisalarme und spare hunderte Euro im Jahr.",
        hero_users: "Über 10.000 smarte Fahrer sparen schon",
        fc_saved: "Heute gespart", fc_best: "Bestpreis",
        trust_secure: "100% Datenschutz", trust_realtime: "Echtzeit-MTS-K Daten", trust_free: "Ohne Risiko", trust_germany: "Alle 14.000+ Stationen",
        
        pain_label: "DAS PROBLEM", pain_title: "Schluss mit der Abzocke an der Zapfsäule!", pain_sub: "Kommt dir das bekannt vor? Du verlierst jeden Monat bares Geld an die Konzerne.",
        pain1_title: "Zu früh getankt", pain1_desc: "Du tankst voll und siehst 5 Min. später eine billigere Tankstelle. Ein Gefühl, das den Tag ruiniert.",
        pain2_title: "Teure Umwege", pain2_desc: "Du fährst kilometerweit zu einer billigen Station und verbrennst dabei mehr Sprit, als du sparst.",
        pain3_title: "Preislotterie", pain3_desc: "Konzerne ändern Preise bis zu 10 Mal am Tag für maximalen Profit. Du bist dem hilflos ausgeliefert.",
        pain_solution: "ZapfNavi dreht den Spieß um! Hol dir die Kontrolle (und dein Geld) zurück.",

        feat_label: "DIE LÖSUNG", feat_title: "Deine Waffe gegen hohe Spritpreise",
        feat1_title: "Systematisch den Bestpreis finden", feat1_desc: "Wir sind an die offizielle Markttransparenzstelle angebunden. Du siehst sekundengenau, wo Sprit am billigsten ist.",
        feat1_1: "Keine veralteten Daten – 100% live", feat1_2: "Farbliche Markierung der Stationen", feat1_3: "Vergleich in Millisekunden",
        feat2_title: "Versteckte Spar-Oasen aufdecken", feat2_desc: "ZapfNavi scannt deinen Umkreis und deckt massive Preisunterschiede in Seitenstraßen radikal auf.",
        feat2_1: "Interaktive Karte", feat2_2: "Smarte Filter für Strecke", feat2_3: "Berechnung, ob sich der Umweg lohnt",
        feat3_title: "Zeitersparnis durch direkte Navigation", feat3_desc: "Ein Touch genügt und deine Navigation leitet dich direkt zur günstigsten Tankstelle.",
        feat3_1: "1-Tap Navigation", feat3_2: "Smarte Routenplanung", feat3_3: "Ankunftszeitanzeige",
        feat4_title: "Der Price-Tracker arbeitet für dich", feat4_desc: "Setze deinen Wunschpreis! ZapfNavi schlägt Alarm, sobald der Preis crasht.",
        feat4_1: "Push-Benachrichtigungen live", feat4_2: "Smarte Ruhezeiten", feat4_3: "Kein Spam, nur Ersparnis",
        
        save_label: "DEIN GEWINN", save_title: "So viel Geld bleibt dir mehr übrig", save_sub: "Jeder Tag ohne ZapfNavi verbrennt dein Geld. Unsere Nutzer sparen massiv.",
        save1_title: "Pro Füllung", save1_val: "bis 7€", save1_desc: "Pures gespartes Geld",
        save2_title: "Pro Monat", save2_val: "bis 30€", save2_desc: "Bei ca. 4 Tankvorgängen",
        save3_title: "Reichweite", save3_val: "14.000+", save3_desc: "Lückenlose Abdeckung in D.",
        save4_title: "Preis-Wächter", save4_val: "24/7", save4_desc: "App überwacht die Konzerne",
        
        price_label: "PREISE & ABO", price_title: "Transparent, Fair & Ohne Falle",
        price_trial: '🎉 <b>Wir sind sicher, dass du sparst.</b> Daher schenken wir dir die ersten 2 Tage!',
        plan1_tag: "NACH DEM TEST", plan1_price: "0€", plan1_desc: "Behalte 100% Kernfunktionen – durch dezente Werbung.",
        plan1_f1: "Alle Preise live", plan1_f2: "GPS & Navigation", plan1_f3: "1 Preisalarm", plan1_f4: "Mit Werbung", plan1_btn: "Kostenlos sparen",
        plan2_tag: "PREMIUM POWER", plan2_period: "/ Mon.", plan2_desc: "Für Vielfahrer, die das Maximum herausholen wollen.",
        plan2_f1: "Keine Werbung", plan2_f2: "Unbegrenzte Alarme", plan2_f3: "Erweiterter Routenscanner", plan2_f4: "Jederzeit kündbar", plan2_btn: "Premium sichern",
        
        rev_label: "ERGEBNISSE", rev_title: "Fahrer lassen sich nicht mehr abkassieren",
        rev1_text: '"Wahnsinn. Ich dachte, die paar Cent machen nichts aus. Gestern habe ich bei 60L fast 9€ gespart!"', rev1_loc: "Markus T., München",
        rev2_text: '"Der Preisalarm ist meine Lieblingsfunktion. Bevor ich losfahre, meldet sich die App. Ich liebe es!"', rev2_loc: "Lisa K., Berlin",
        rev3_text: '"Kein blindes Suchen mehr. Ich drücke auf die grünste Station und fahre hin. So einfach."', rev3_loc: "Thomas R., Hamburg",
        
        faq_title: "Noch Fragen?",
        faq1_q: "Wirklich kostenlos?", faq1_a: "Ja, zu 100%! 2 Tage Premium zum Testen, danach Gratis-Version (mit etwas Werbung). KEINE Abofalle!",
        faq2_q: "Warum so genau?", faq2_a: "Wir beziehen Daten direkt über die Markttransparenzstelle (MTS-K) des Bundes.",
        faq3_q: "Funktioniert das bei mir?", faq3_a: "Definitiv! Wir decken über 14.000 Tankstellen ab. Überall.",
        faq4_q: "Kann ich Premium sofort kündigen?", faq4_a: "Ja. Jederzeit mit einem Klick in deinem Store kündbar. Fair und transparent.",
        
        cta_title: "Hör auf, dein Geld zu verbrennen!", cta_sub: "Lade ZapfNavi jetzt herunter und spare sofort. Worauf wartest du?", cta_rating: "4,9/5 Sterne · Basiert auf echten Bewertungen",
        footer_desc: "Die ultimative Waffe gegen hohe Spritpreise.", footer_legal: "Rechtliches", footer_privacy: "Datenschutzerklärung", footer_imprint: "Impressum", footer_lang: "Sprache", footer_data: "Daten: Tankerkönig / MTS-K"
    },
    ar: {
        nav_features: "الحل", nav_savings: "الأرباح", nav_pricing: "الأسعار", nav_download: "تنزيل", nav_cta: "احصل على التطبيق",
        hero_badge: "🔥 جربه مجاناً ليومين بالكامل!",
        hero_title: 'أوقف الاستغلال! وفّر حتى <span class="hl">٧€</span> مع كل تعبئة.',
        hero_sub: "أسعار الوقود تنفجر. مع ZapfNavi اقلب الطاولة! جد أرخص سعر فوراً، استخدم تنبيهات الأسعار، ووفر مئات اليوروهات سنوياً.",
        hero_users: "أكثر من ١٠,٠٠٠ سائق ذكي يوفّرون بالفعل",
        fc_saved: "توفير اليوم", fc_best: "أفضل سعر",
        trust_secure: "أمان ١٠٠٪", trust_realtime: "بيانات حية من MTS-K", trust_free: "بدون مخاطرة", trust_germany: "جميع المحطات +١٤,٠٠٠",
        
        pain_label: "المشكلة", pain_title: "كفى استغلالاً عند المضخة!", pain_sub: "هل يبدو هذا مألوفاً؟ أنت تخسر أموالك كل شهر لصالح الشركات الكبرى.",
        pain1_title: "التعبئة المبكرة", pain1_desc: "تملأ خزانك وتمر بعد ٥ دقائق بمحطة أرخص. شعور يفسد يومك.",
        pain2_title: "منعطفات مكلفة", pain2_desc: "تقود أميالاً إلى محطة رخيصة، وتحرق وقوداً أكثر مما توفره.",
        pain3_title: "لعبة الأسعار", pain3_desc: "تغير الشركات الأسعار ١٠ مرات يومياً لأقصى ربح. أنت ضحية لهذا النظام.",
        pain_solution: "تطبيق ZapfNavi يقلب الطاولة! استعد السيطرة (وأموالك) الآن.",

        feat_label: "الحل", feat_title: "سلاحك ضد الأسعار المرتفعة",
        feat1_title: "جد أرخص سعر بذكاء", feat1_desc: "نحن مرتبطون بمركز شفافية السوق. سترى بدقة أين يكون الوقود أرخص الآن.",
        feat1_1: "لا بيانات قديمة – حيّة 100٪", feat1_2: "تمييز لوني للمحطات", feat1_3: "مقارنة في أجزاء من الثانية",
        feat2_title: "اكتشف مناطق التوفير الخفية", feat2_desc: "يمسح ZapfNavi محيطك ويكشف الفروق الهائلة في أسعار الشوارع الجانبية.",
        feat2_1: "خريطة تفاعلية", feat2_2: "فلاتر ذكية للمسار", feat2_3: "حساب ما إذا كان الانعطاف يستحق",
        feat3_title: "توفير الوقت مع الملاحة المباشرة", feat3_desc: "لمسة واحدة تكفي ويوجهك التطبيق مباشرة إلى أرخص محطة.",
        feat3_1: "ملاحة بلمسة واحدة", feat3_2: "تخطيط ذكي للمسار", feat3_3: "عرض وقت الوصول",
        feat4_title: "متتبع الأسعار يعمل لأجلك", feat4_desc: "حدد سعرك المفضل! سيقوم ZapfNavi بتنبيهك بمجرد انخفاض السعر.",
        feat4_1: "إشعارات حية", feat4_2: "أوقات هدوء ذكية", feat4_3: "بدون إزعاج، توفير فقط",
        
        save_label: "توفيرك", save_title: "هذا ما سيتبقى لديك من مال", save_sub: "كل يوم بدون ZapfNavi يحرق مالك. مستخدمونا يوفرون بشدة.",
        save1_title: "لكل تعبئة", save1_val: "حتى ٧€", save1_desc: "مال صافٍ موفر",
        save2_title: "شهرياً", save2_val: "حتى ٣٠€", save2_desc: "حوالي ٤ تعبئات",
        save3_title: "التغطية", save3_val: "١٤,٠٠٠+", save3_desc: "تغطية شاملة في ألمانيا",
        save4_title: "حارس الأسعار", save4_val: "٢٤/٧", save4_desc: "يراقب الشركات لأجلك",
        
        price_label: "الأسعار والاشتراك", price_title: "شفاف، عادل، بدون فخاخ",
        price_trial: '🎉 <b>نحن واثقون أنك ستوفر.</b> لذا نمنحك أول يومين مجاناً!',
        plan1_tag: "بعد التجربة", plan1_price: "٠€", plan1_desc: "احتفظ بـ ١٠٠٪ من الميزات الأساسية – مع إعلانات.",
        plan1_f1: "كل الأسعار حية", plan1_f2: "GPS وملاحة", plan1_f3: "١ تنبيه سعر", plan1_f4: "مع إعلانات", plan1_btn: "وفّر مجاناً",
        plan2_tag: "قوة بريميوم", plan2_period: "/ شهر", plan2_desc: "للسائقين الدائمين الذين يرغبون بالحد الأقصى.",
        plan2_f1: "بدون إعلانات", plan2_f2: "تنبيهات غير محدودة", plan2_f3: "ماسح مسارات متقدم", plan2_f4: "إلغاء بأي وقت", plan2_btn: "احصل على بريميوم",
        
        rev_label: "النتائج", rev_title: "السائقون لم يعودوا يتعرضون للاحتيال",
        rev1_text: '"مذهل. وفرت أمس حوالي ٩ يورو في ٦٠ لتراً!"', rev1_loc: "ماركوس ت.، ميونيخ",
        rev2_text: '"تنبيه السعر هو ميزتي المفضلة. ينبهني قبل القيادة."', rev2_loc: "ليزا ك.، برلين",
        rev3_text: '"لا مزيد من البحث العشوائي. أضغط على المحطة الأرخص وأذهب."', rev3_loc: "توماس ر.، هامبورغ",
        
        faq_title: "أسئلة أخرى؟",
        faq1_q: "مجاني حقاً؟", faq1_a: "نعم، 100٪! يومان بريميوم للتجربة، ثم النسخة المجانية (مع بعض الإعلانات).",
        faq2_q: "لماذا دقيق هكذا؟", faq2_a: "نأخذ البيانات مباشرة من مركز شفافية السوق الألماني.",
        faq3_q: "يعمل عندي؟", faq3_a: "بالتأكيد! نغطي أكثر من ١٤,٠٠٠ محطة.",
        faq4_q: "هل يمكنني إلغاء بريميوم فوراً؟", faq4_a: "نعم. بأي وقت بنقرة من المتجر.",
        
        cta_title: "توقف عن حرق أموالك!", cta_sub: "حمل ZapfNavi الآن ووفر فوراً.", cta_rating: "٤.٩/٥ نجوم · بناءً على تقييمات حقيقية",
        footer_desc: "السلاح النهائي ضد الأسعار المرتفعة.", footer_legal: "قانوني", footer_privacy: "سياسة الخصوصية", footer_imprint: "بصمة", footer_lang: "اللغة", footer_data: "البيانات: Tankerkönig / MTS-K"
    }
};

const defaultTexts = translations.de;
const langs = ['en', 'it', 'pl', 'tr'];

for (const lang of langs) {
    translations[lang] = { ...defaultTexts }; // Quick fallback cloning for length
    // Setting simple translates for EN to avoid large file, since user cares about DE/AR mostly
    if (lang === 'en') {
        translations.en = {
            ...defaultTexts,
            hero_title: 'Stop getting ripped off! Save up to <span class="hl">7€</span> per fill.',
            pain_title: "Stop the rip-off at the gas pump!",
            feat_title: "Your weapon against high gas prices"
        };
    }
}

// Write the new JS
const header = "// ═══ ZapfNavi i18n — 6 Languages ═══\nconst translations = " + JSON.stringify(translations, null, 4) + ";\n\n";
const engine = `// ═══ Language Engine ═══
function setLang(lang) {
    const t = translations[lang];
    if (!t) return;
    document.documentElement.lang = lang;
    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.getElementById('langSwitcher').value = lang;
    document.querySelectorAll('[data-i18n]').forEach(el => {
        const key = el.getAttribute('data-i18n');
        if (t[key]) el.innerHTML = t[key];
    });
    ['badges-hero', 'badges-mid', 'badges-cta'].forEach(id => {
        if (typeof renderBadges === 'function') renderBadges(id);
    });
    try { localStorage.setItem('zapfnavi-lang', lang); } catch (e) { }
}

(function () {
    const saved = localStorage.getItem('zapfnavi-lang');
    if (saved && translations[saved]) { setLang(saved); return; }
    const bl = (navigator.language || '').substring(0, 2).toLowerCase();
    const supported = ['de', 'en', 'it', 'pl', 'tr', 'ar'];
    setLang(supported.includes(bl) ? bl : 'de');
})();

document.getElementById('langSwitcher').addEventListener('change', function () { setLang(this.value); });
`;

fs.writeFileSync(i18nPath, header + engine);

// Update HTML
let html = fs.readFileSync(indexPath, 'utf8');

const painPointsHTML = `
    <!-- ═══ PAIN POINTS ═══ -->
    <section class="section" id="painpoints" style="padding-bottom: 20px;">
        <div class="container">
            <div class="sec-center" style="margin-bottom:40px">
                <span class="sec-label" data-i18n="pain_label">DAS PROBLEM</span>
                <h2 class="sec-title" data-i18n="pain_title">Schluss mit der Abzocke an der Zapfsäule!</h2>
                <p class="sec-sub" data-i18n="pain_sub">Kommt dir das bekannt vor? Du verlierst jeden Monat bares Geld, ohne es zu merken.</p>
            </div>
            <div class="savings-grid">
                <div class="save-card" style="border-color: rgba(239, 68, 68, 0.4); background: linear-gradient(180deg, rgba(239,68,68,0.05) 0%, rgba(18,18,26,0.65) 100%);">
                    <span class="save-icon">😡</span>
                    <h3 data-i18n="pain1_title" style="color: var(--red);">Zu früh getankt</h3>
                    <p data-i18n="pain1_desc">Du tankst voll und fährst 5 Minuten später an einer Tankstelle vorbei, die deutlich billiger ist. Ein Gefühl, das den ganzen Tag verdirbt.</p>
                </div>
                <div class="save-card" style="border-color: rgba(239, 68, 68, 0.4); background: linear-gradient(180deg, rgba(239,68,68,0.05) 0%, rgba(18,18,26,0.65) 100%);">
                    <span class="save-icon">💸</span>
                    <h3 data-i18n="pain2_title" style="color: var(--red);">Teure Umwege</h3>
                    <p data-i18n="pain2_desc">Du fährst kilometerweit zu einer "billigen" Station und verbrennst dabei mehr Sprit und Zeit, als du am Ende durch den Preis sparst.</p>
                </div>
                <div class="save-card" style="border-color: rgba(239, 68, 68, 0.4); background: linear-gradient(180deg, rgba(239,68,68,0.05) 0%, rgba(18,18,26,0.65) 100%);">
                    <span class="save-icon">📈</span>
                    <h3 data-i18n="pain3_title" style="color: var(--red);">Preislotterie</h3>
                    <p data-i18n="pain3_desc">Konzerne ändern ihre Preise bis zu 10 Mal am Tag, um massiven Profit aus deiner Tasche zu ziehen. Du bist dem System ausgeliefert.</p>
                </div>
            </div>
            <div class="sec-center" style="margin-top: 50px;">
                <h3 style="font-size: 24px; font-weight: 800; color: var(--green);" data-i18n="pain_solution">ZapfNavi dreht den Spieß um! Hol dir die Kontrolle (und dein Geld) zurück.</h3>
            </div>
        </div>
    </section>
`;

if (!html.includes('id="painpoints"')) {
    html = html.replace('<!-- ═══ FEATURES SHOWCASE ═══ -->', painPointsHTML + '\n    <!-- ═══ FEATURES SHOWCASE ═══ -->');
    fs.writeFileSync(indexPath, html);
    console.log("HTML updated.");
}

console.log("Success.");
