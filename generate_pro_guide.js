const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const htmlContent = `<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="UTF-8">
<title>AppRadar: B2B SaaS Growth & Digital Marketing Master Playbook</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Hind+Siliguri:wght@400;500;600;700&family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap');

  @page {
    size: A4;
    margin: 12mm 12mm 12mm 12mm;
    @bottom-right {
      content: counter(page);
    }
  }

  * {
    box-sizing: border-box;
    margin: 0;
    padding: 0;
  }

  body {
    font-family: 'Hind Siliguri', 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    color: #0f172a;
    background-color: #ffffff;
    line-height: 1.55;
    font-size: 13px;
    -webkit-print-color-adjust: exact;
    print-color-adjust: exact;
  }

  .cover-hero {
    background: radial-gradient(circle at top right, #1e1b4b, #0f172a 80%);
    color: #ffffff;
    padding: 28px 24px;
    border-radius: 10px;
    margin-bottom: 20px;
    border: 1px solid #312e81;
  }

  .executive-badge {
    display: inline-flex;
    align-items: center;
    gap: 6px;
    background: rgba(99, 102, 241, 0.25);
    border: 1px solid #6366f1;
    color: #c7d2fe;
    font-size: 10.5px;
    font-weight: 700;
    padding: 3px 10px;
    border-radius: 20px;
    text-transform: uppercase;
    letter-spacing: 0.8px;
    margin-bottom: 12px;
  }

  .hero-title {
    font-size: 24px;
    font-weight: 800;
    line-height: 1.25;
    color: #ffffff;
    margin-bottom: 8px;
    letter-spacing: -0.3px;
  }

  .hero-desc {
    font-size: 13px;
    color: #94a3b8;
    line-height: 1.5;
    max-width: 95%;
  }

  .meta-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 10px;
    margin-top: 16px;
    padding-top: 14px;
    border-top: 1px solid rgba(255,255,255,0.1);
  }

  .meta-item {
    font-size: 11px;
  }
  .meta-label {
    color: #64748b;
    text-transform: uppercase;
    font-weight: 600;
    letter-spacing: 0.5px;
    margin-bottom: 2px;
  }
  .meta-val {
    color: #e2e8f0;
    font-weight: 700;
  }

  .section {
    margin-bottom: 20px;
    page-break-inside: avoid;
  }

  .page-break {
    page-break-before: always;
  }

  .sec-header {
    display: flex;
    align-items: center;
    gap: 8px;
    border-bottom: 2px solid #e2e8f0;
    padding-bottom: 6px;
    margin-bottom: 12px;
  }

  .sec-pill {
    background: #0f172a;
    color: #ffffff;
    font-family: 'Inter', sans-serif;
    font-size: 11px;
    font-weight: 800;
    padding: 3px 8px;
    border-radius: 4px;
    letter-spacing: 0.5px;
  }

  .sec-title {
    font-size: 16px;
    font-weight: 700;
    color: #0f172a;
    letter-spacing: -0.2px;
  }

  .sec-timing {
    margin-left: auto;
    font-size: 11px;
    font-weight: 600;
    color: #475569;
    background: #f1f5f9;
    padding: 2px 8px;
    border-radius: 4px;
    font-family: 'Inter', sans-serif;
  }

  .card {
    background: #ffffff;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    padding: 12px 14px;
    margin-bottom: 12px;
    box-shadow: 0 1px 3px rgba(0,0,0,0.03);
  }

  .card-highlight {
    background: #f8fafc;
    border-left: 4px solid #4f46e5;
  }

  .card-emerald {
    background: #f0fdf4;
    border-left: 4px solid #10b981;
    border-color: #bbf7d0 #bbf7d0 #bbf7d0 #10b981;
  }

  .card-amber {
    background: #fffbeb;
    border-left: 4px solid #f59e0b;
    border-color: #fde68a #fde68a #fde68a #f59e0b;
  }

  .card-heading {
    font-size: 13.5px;
    font-weight: 700;
    color: #0f172a;
    margin-bottom: 6px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .grid-2 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
    margin-bottom: 12px;
  }

  .grid-3 {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 10px;
    margin-bottom: 12px;
  }

  .metric-box {
    background: #f8fafc;
    border: 1px solid #e2e8f0;
    border-radius: 6px;
    padding: 8px 10px;
    text-align: center;
  }
  .metric-num {
    font-size: 18px;
    font-weight: 800;
    color: #4f46e5;
    font-family: 'Inter', sans-serif;
  }
  .metric-label {
    font-size: 11px;
    color: #64748b;
    font-weight: 600;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin: 8px 0 12px 0;
    font-size: 12px;
  }

  th, td {
    border: 1px solid #cbd5e1;
    padding: 6px 9px;
    text-align: left;
    vertical-align: top;
  }

  th {
    background: #0f172a;
    color: #ffffff;
    font-weight: 600;
    font-family: 'Inter', sans-serif;
    font-size: 11.5px;
  }

  tr:nth-child(even) {
    background: #f8fafc;
  }

  .sop-step {
    display: flex;
    gap: 10px;
    margin-bottom: 8px;
    font-size: 12.5px;
  }

  .sop-badge {
    background: #e0e7ff;
    color: #3730a3;
    font-weight: 800;
    font-size: 10.5px;
    padding: 2px 7px;
    border-radius: 4px;
    height: fit-content;
    white-space: nowrap;
    font-family: 'Inter', sans-serif;
  }

  .sop-text {
    flex: 1;
  }

  .template-container {
    background: #090d16;
    border: 1px solid #1e293b;
    border-radius: 8px;
    padding: 12px 14px;
    margin: 8px 0 12px 0;
    color: #e2e8f0;
    font-family: 'JetBrains Mono', Consolas, monospace;
    font-size: 11.5px;
    line-height: 1.45;
    white-space: pre-wrap;
    word-break: break-word;
  }

  .template-tag {
    display: inline-block;
    background: #2563eb;
    color: #ffffff;
    font-family: 'Inter', sans-serif;
    font-size: 10px;
    font-weight: 700;
    padding: 2px 8px;
    border-radius: 4px;
    margin-bottom: 8px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }

  .highlight-var {
    color: #38bdf8;
    font-weight: 600;
  }

  .schedule-bullet {
    list-style: none;
    margin-left: 2px;
  }
  .schedule-bullet li {
    position: relative;
    padding-left: 18px;
    margin-bottom: 6px;
    font-size: 12.5px;
  }
  .schedule-bullet li::before {
    content: "▸";
    position: absolute;
    left: 2px;
    color: #4f46e5;
    font-weight: bold;
    font-size: 14px;
  }

  .kpi-pill {
    display: inline-block;
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 10px;
    font-weight: 700;
    font-family: 'Inter', sans-serif;
  }
  .kpi-high { background: #dcfce7; color: #15803d; }
  .kpi-med { background: #fef3c7; color: #b45309; }

  .footer-bar {
    text-align: center;
    border-top: 1px solid #e2e8f0;
    padding-top: 10px;
    margin-top: 20px;
    font-size: 11px;
    color: #64748b;
  }
</style>
</head>
<body>

  <!-- COVER / EXECUTIVE SUMMARY -->
  <div class="cover-hero">
    <div class="executive-badge">Official Go-To-Market Blueprint</div>
    <h1 class="hero-title">AppRadar: B2B SaaS Growth & Marketing Master Plan</h1>
    <p class="hero-desc">একজন সিনিয়র SaaS গ্রোথ ডিরেক্টর যেভাবে একটি সফটওয়্যার প্রোডাক্টকে ০ থেকে স্কেল করেন — কোথায়, কখন, কীভাবে এবং কোন প্ল্যাটফর্মে কী কী পোস্ট করবেন তার নির্ভুল এক্সিকিউশন এসওপি (SOP)।</p>
    
    <div class="meta-grid">
      <div class="meta-item">
        <div class="meta-label">প্রোডাক্ট ক্যাটাগরি</div>
        <div class="meta-val">B2B ASO & Intelligence</div>
      </div>
      <div class="meta-item">
        <div class="meta-label">টার্গেট অডিয়েন্স</div>
        <div class="meta-val">Indie Devs & Agencies</div>
      </div>
      <div class="meta-item">
        <div class="meta-label">টার্গেট গোল (Day 30)</div>
        <div class="meta-val">১০০+ সাইনআপ, ৫-১০ প্রো সেল</div>
      </div>
      <div class="meta-item">
        <div class="meta-label">বাজেট রিকোয়ারমেন্ট</div>
        <div class="meta-val">$0 (১০০% অর্গানিক গ্রোথ)</div>
      </div>
    </div>
  </div>

  <!-- SECTION 1: ICP DEFINITION & VALUE PROPOSITION -->
  <div class="section">
    <div class="sec-header">
      <span class="sec-pill">PHASE 1</span>
      <span class="sec-title">আদর্শ কাস্টমার প্রোফাইল (ICP) ও মূল ভ্যালু প্রপোজিশন</span>
      <span class="sec-timing">ফাউন্ডেশন</span>
    </div>

    <div class="grid-2">
      <div class="card card-highlight">
        <div class="card-heading">🎯 প্রাইমারি টার্গেট কাস্টমার (ICP 1 & 2)</div>
        <p><strong>১. Indie App Developers & Solo Founders:</strong> যারা নিজেদের অ্যাপের ASO ট্র্যাক করতে চান কিন্তু Sensor Tower বা App Annie-কে মাসে $২০০-$৫০০ দিতে পারেন না।</p>
        <p><strong>২. Boutique ASO / App Marketing Agencies:</strong> যারা ক্লায়েন্টদের অডিট ও কম্পিটিটর রিপোর্ট দিতে ঘন্টার পর ঘন্টা ব্যয় করেন।</p>
      </div>
      <div class="card card-emerald">
        <div class="card-heading">⚡ আপনার "Unfair Advantage" (কেন মানুষ কিনবে?)</div>
        <p><strong>• প্রাইসিং শক:</strong> এন্টারপ্রাইজ টুল $৩,০০০/বছর বনাম AppRadar মাত্র $১৯-$২৯/মাস।</p>
        <p><strong>• ওয়ান-ক্লিক রিপোর্ট:</strong> ম্যানুয়ালি ডেটা সাজানোর ঝামেলা নেই, ড্যাশবোর্ড থেকে সরাসরি কম্পিটিটর টিয়ারডাউন রিপোর্ট তৈরি।</p>
        <p><strong>• ক্লিন UI:</strong> জটিল এন্টারপ্রাইজ ড্যাশবোর্ডের চেয়ে ৫ গুণ দ্রুত ও পরিষ্কার।</p>
      </div>
    </div>
  </div>

  <!-- SECTION 2: TRACKING & INFRASTRUCTURE -->
  <div class="section">
    <div class="sec-header">
      <span class="sec-pill">PHASE 2</span>
      <span class="sec-title">মার্কেটিং শুরুর আগে ট্র্যাকিং সেটআপ (১ম দিন)</span>
      <span class="sec-timing">Day 1</span>
    </div>

    <p>কোথা থেকে ভিজিটর আসছে তা না মাপলে মার্কেটিং অন্ধের মতো কাজ করে। ৩টি গুরুত্বপূর্ণ টুল সেট করুন:</p>

    <table>
      <thead>
        <tr>
          <th style="width: 20%;">টুল</th>
          <th style="width: 35%;">কেন ব্যবহার করবেন</th>
          <th style="width: 45%;">কীভাবে কনফিগার করবেন</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>UTM Generator</strong></td>
          <td>কোন সোশ্যাল পোস্ট থেকে ট্রাফিক আসছে তা ট্র্যাক করা।</td>
          <td>ফ্রি টুল: <code>ga-dev-tools.google/campaign-url-builder</code><br>উদাহরণ: <code>yourlink.com?utm_source=reddit&utm_medium=post&utm_campaign=sideproject_launch</code></td>
        </tr>
        <tr>
          <td><strong>Free Analytics</strong></td>
          <td>ইউজার ওয়েবসাইটে এসে কোথায় ক্লিক করছে দেখা।</td>
          <td>Google Analytics 4 অথবা PostHog (ফ্রি টিয়ারে মাসে ১ মিলিয়ন ইভেন্ট ফ্রি)।</td>
        </tr>
        <tr>
          <td><strong>Loom Teardown</strong></td>
          <td>৬০-৯০ সেকেন্ডের একটি ডেমো ভিডিও তৈরি।</td>
          <td>Loom দিয়ে বিনামূল্যে অ্যাপের ড্যাশবোর্ড, টপ চার্ট ও কম্পিটিটর সার্চের স্ক্রিন রেকর্ড করুন।</td>
        </tr>
      </tbody>
    </table>
  </div>

  <!-- SECTION 3: PLATFORM PLAYBOOK - REDDIT -->
  <div class="section page-break">
    <div class="sec-header">
      <span class="sec-pill">PLATFORM 1</span>
      <span class="sec-title">Reddit Execution SOP (দ্য নাম্বার-১ ট্রাফিক সোর্স)</span>
      <span class="sec-timing">Best Time: মঙ্গল ও বুধবার, বাংলাদেশ সময় সন্ধ্যা ৭টা - রাত ৯টা (EST 9 AM)</span>
    </div>

    <div class="card card-amber">
      <div class="card-heading">⚠️ রেডিটের গোপন নিয়ম (Karma & Spam Policy)</div>
      <p>রেডিটে কখনও বলবেন না <em>“Buy my tool”</em> বা <em>“Check my new startup”</em>। রেডিটে সবসময় শেয়ার করতে হয় <strong>“I solved my own problem and making it free for you”</strong> (প্রবলেম-ফার্স্ট অ্যাপ্রোচ)।</p>
    </div>

    <div class="sop-step">
      <div class="sop-badge">পদক্ষেপ ১</div>
      <div class="sop-text">টার্গেট সাবরেডিটে ঢুকুন: <code>r/SideProject</code>, <code>r/iOSProgramming</code>, <code>r/androiddev</code>, <code>r/IndieHackers</code>।</div>
    </div>
    <div class="sop-step">
      <div class="sop-badge">পদক্ষেপ ২</div>
      <div class="sop-text">পোস্টের সাথে অ্যাপের ১টি সুন্দর স্ক্রিনশট বা ছোট GIF যুক্ত করুন (ভিডিও বা ইমেজ পোস্ট টেক্সট পোস্টের চেয়ে ৩ গুণ বেশি রিচ পায়)।</div>
    </div>
    <div class="sop-step">
      <div class="sop-badge">পদক্ষেপ ৩</div>
      <div class="sop-text">নিচের হাই-কনভার্টিং কপিটি হুবহু ব্যবহার করুন:</div>
    </div>

    <div class="template-container">
<span class="template-tag">High-CVR Reddit Copy</span>
<strong>Title:</strong>
I was tired of Sensor Tower charging $250/mo just to see competitor ranking shifts, so I spent 3 months building a lightweight alternative for indie devs. Free access!

<strong>Body:</strong>
Hey r/SideProject 👋

Like many of you, I've had mobile apps die on the App Store simply because competitors optimized their keywords and category ranking while I was blind to it.

When I looked into standard ASO tools:
- Sensor Tower: starts at $200-$400/mo
- MobileAction: $150+/mo minimum
- App Annie / Data.ai: Enterprise only

As a solo dev, paying $2,500/year just to track a few apps is insane.

So I built **AppRadar** — designed specifically for developers, small studios, and indie hackers.

🔥 What it does right now:
1. Hourly iOS & Google Play Top Charts movements across 50+ categories
2. Side-by-side Competitor Matrix (track installs, ratings, velocity, and keyword shifts)
3. Review mining (instantly see what users hate about your competitors so you can build it better)
4. Downloadable teardown PDF/CSV reports

🚀 It is live, and I am giving **100% FREE access** to everyone in this community to get real, unfiltered feedback.

🔗 Try it here: <span class="highlight-var">[আপনার লাইভ ওয়েবসাইটের লিংক + UTM]</span>

👉 **Drop your app name or Play/App Store link in the comments**, and I'll generate a custom competitor teardown report for your app right now!

What feature would make this an everyday tool for you? Let me know!
    </div>
  </div>

  <!-- SECTION 4: PLATFORM PLAYBOOK - LINKEDIN -->
  <div class="section page-break">
    <div class="sec-header">
      <span class="sec-pill">PLATFORM 2</span>
      <span class="sec-title">LinkedIn B2B Outreach SOP (পেইড এজেন্সি ক্লায়েন্ট পাওয়ার কৌশল)</span>
      <span class="sec-timing">Best Time: সোম থেকে বৃহস্পতিবার, বাংলাদেশ সময় বিকেল ৩টা - ৫টা (UK/EU সকাল)</span>
    </div>

    <p>এজেন্সিগুলো প্রতিটি ক্লায়েন্ট থেকে মাসে $১,০০০-$৫,০০০ ফি নেয়। তারা একটি ভালো টুলের জন্য প্রতি মাসে $২৯-$৪৯ অনায়াসে পে করবে যদি তা তাদের কাজের সময় বাঁচায়।</p>

    <div class="card card-highlight">
      <div class="card-heading">🎯 লিঙ্কডিনে সঠিক ক্লায়েন্ট কীভাবে ফিল্টার করবেন?</div>
      <p>LinkedIn Search Bar-এ লিখুন: <code>"ASO Specialist" OR "App Marketing Manager" OR "Mobile Growth Lead"</code><br>
      • লোকেশন ফিল্টার দিন: United States, United Kingdom, Germany, Netherlands, India.<br>
      • প্রতিদিন ১০ জন মানুষকে কানেকশন রিকোয়েস্ট পাঠান (Personalized Note সহ)।</p>
    </div>

    <div class="template-container">
<span class="template-tag">LinkedIn Connection Note (300 Characters Max)</span>
Hi <span class="highlight-var">[First Name]</span>, saw your work handling ASO for mobile clients. Sensor Tower is getting ridiculously expensive ($300+/mo). Built AppRadar to give agencies instant competitor matrix tracking & teardown reports for 1/10th the cost. Would love to send you a free agency trial!
    </div>

    <div class="template-container">
<span class="template-tag">LinkedIn Direct Message (কানেকশন গ্রহণ করার পর)</span>
Hi <span class="highlight-var">[First Name]</span>,

Thanks for connecting! 

I know most ASO specialists spend 2-3 hours manually compiling competitor ranking changes and review sentiments for client presentations.

We built **AppRadar** to automate this:
• Real-time Top Charts tracking (iOS & Android)
• Side-by-side Competitor Matrix
• 1-Click Client-Ready Teardown Reports

Here is a 60-second preview of how it looks: <span class="highlight-var">[Loom Video Link বা স্ক্রিনশট]</span>

I’ve activated a **30-Day VIP Pro Pass** for you (no credit card required) so you can test it on your next client audit:
👉 <span class="highlight-var">[আপনার ওয়েবসাইটের লিংক]</span>

Would love to know: what's the most annoying part of your current competitor reporting workflow?

Best,
<span class="highlight-var">[আপনার নাম]</span>
Founder, AppRadar
    </div>
  </div>

  <!-- SECTION 5: PLATFORM PLAYBOOK - TWITTER/X -->
  <div class="section page-break">
    <div class="sec-header">
      <span class="sec-pill">PLATFORM 3</span>
      <span class="sec-title">Twitter (X) "Build in Public" সাপ্তাহিক ক্যালেন্ডার</span>
      <span class="sec-timing">Schedule: প্রতিদিন ১টি টুইট (বাংলাদেশ সময় দুপুর ১২টা অথবা রাত ৮টা)</span>
    </div>

    <p>Twitter-এ <code>#buildinpublic</code> এবং <code>#indiedev</code> কমিউনিটিতে হাজার হাজার মোবাইল ডেভেলপার সবসময় সক্রিয়। নিচে পুরো সপ্তাহের রেডিমেড কনটেন্ট প্ল্যান দেওয়া হলো:</p>

    <table>
      <thead>
        <tr>
          <th style="width: 15%;">বার</th>
          <th style="width: 25%;">কন্টেন্টের বিষয়</th>
          <th style="width: 60%;">টুইটের কাঠামো ও কপি ফ্রেমওয়ার্ক</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>সোমবার</strong></td>
          <td>Competitor Teardown (কেস স্টাডি)</td>
          <td>"I analyzed how Duolingo dominates their App Store category against 5 competitors. Here is the keyword & sentiment breakdown (Screenshots from AppRadar) 🧵👇"</td>
        </tr>
        <tr>
          <td><strong>মঙ্গলবার</strong></td>
          <td>Cost Comparison (পেইন পয়েন্ট)</td>
          <td>"Why does tracking 5 competitors on mobile cost $2,400/yr on Sensor Tower? It shouldn’t. Built an indie alternative for $19/mo. Here is how it works..."</td>
        </tr>
        <tr>
          <td><strong>বুধবার</strong></td>
          <td>Viral Free Audit Hook</td>
          <td>"Doing free ASO teardowns today! Drop your iOS/Android app link below 👇 and I’ll run a live competitor matrix report for you using AppRadar."</td>
        </tr>
        <tr>
          <td><strong>বৃহস্পতিবার</strong></td>
          <td>Feature Drop / Behind the scenes</td>
          <td>"Just shipped hourly top chart change detection! Here's how our Flutter web app visualizes the rank shifts in real-time. Link in bio."</td>
        </tr>
        <tr>
          <td><strong>শুক্রবার</strong></td>
          <td>Weekly Milestone / Numbers</td>
          <td>"Week 1 of AppRadar: 48 signups, 120 apps tracked, 4 competitor reports generated. Biggest lesson: Indie devs really want simple review mining."</td>
        </tr>
      </tbody>
    </table>

    <div class="card card-emerald">
      <div class="card-heading">🔥 প্রো টিপ: রিচ ৫ গুণ বাড়ানোর ট্রিক</div>
      <p>টুইট করার পর প্রথম ৩০ মিনিটে অন্য ৩-৫ জন মোবাইল অ্যাপ ডেভেলপারের পোস্টে গিয়ে গঠনমূলক মন্তব্য করুন। এতে টুইটারের অ্যালগরিদম আপনার প্রোফাইলকে অন্যদের টাইমলাইনে বুস্ট করবে।</p>
    </div>
  </div>

  <!-- SECTION 6: PRODUCT HUNT MASTERCLASS -->
  <div class="section page-break">
    <div class="sec-header">
      <span class="sec-pill">PLATFORM 4</span>
      <span class="sec-title">Product Hunt Launch Day: Hour-by-Hour Playbook</span>
      <span class="sec-timing">Target Day: মঙ্গলবার (PST 12:01 AM = বাংলাদেশ সময় দুপুর ১:০১ টা)</span>
    </div>

    <p>Product Hunt-এ সেরা দিন হলো **মঙ্গলবার**। এটি টেক কমিউনিটির সবচেয়ে সক্রিয় দিন। নিচে লঞ্চের ২৪ ঘণ্টার নিখুঁত সময়সূচি দেওয়া হলো:</p>

    <div class="grid-3">
      <div class="metric-box">
        <div class="metric-num">Top 5</div>
        <div class="metric-label">Daily Goal Badge</div>
      </div>
      <div class="metric-box">
        <div class="metric-num">300+</div>
        <div class="metric-label">Expected Day-1 Signups</div>
      </div>
      <div class="metric-box">
        <div class="metric-num">00:01 PST</div>
        <div class="metric-label">Exact Launch Time</div>
      </div>
    </div>

    <ul class="schedule-bullet">
      <li><strong>দুপুর ১:০১ টা (00:01 PST) - Launch Goes Live:</strong> প্রোডাক্ট লাইভ হওয়া মাত্রই Maker Comment পোস্ট করুন (পূর্বের পেজে দেওয়া কপি ব্যবহার করে)।</li>
      <li><strong>দুপুর ১:১৫ টা - Personal Circle Alert:</strong> আপনার পরিচিত ডেভেলপার বন্ধু ও টিমমেটদের জানান: <em>“We are live on Product Hunt! Would love your honest thoughts and support on the launch page.”</em> (সরাসরি 'upvote me' বলবেন না, PH অ্যালগরিদম ফ্ল্যাগ করতে পারে)।</li>
      <li><strong>বিকেল ৩:০০ টা - Social Media Blitz:</strong> Twitter, LinkedIn, Reddit (r/SideProject)-এ পোস্ট দিন: <em>“We just launched AppRadar on Product Hunt today! Checking comments all day.”</em></li>
      <li><strong>সন্ধ্যা ৬:০০ টা থেকে রাত ১২:০০ টা - US Audience Peak:</strong> আমেরিকার মানুষ যখন অফিসে ঢুকবে, তখন কমেন্টের সংখ্যা দ্রুত বাড়বে। প্রতিটি কমেন্টের উত্তর দিন ৫ মিনিটের মধ্যে।</li>
      <li><strong>পরের দিন দুপুর ১:০০ টা - Launch Closes:</strong> ফলাফল প্রকাশ পাবে এবং আপনি 'Top Product' ব্যাজ আপনার ওয়েবসাইটে যুক্ত করতে পারবেন।</li>
    </ul>
  </div>

  <!-- SECTION 7: 30-DAY CALENDAR & KPIs -->
  <div class="section page-break">
    <div class="sec-header">
      <span class="sec-pill">EXECUTION</span>
      <span class="sec-title">৩০ দিনের মাস্টার মার্কেটিং ক্যালেন্ডার ও কেপিআই (KPI) স্কোরকার্ড</span>
      <span class="sec-timing">Day 1 – Day 30</span>
    </div>

    <table>
      <thead>
        <tr>
          <th style="width: 18%;">সময়সীমা</th>
          <th style="width: 42%;">দৈনিক করণীয় কাজ (Daily Actions)</th>
          <th style="width: 25%;">টার্গেট মেট্রিক্স (KPI)</th>
          <th style="width: 15%;">প্রায়োরিটি</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><strong>সপ্তাহ ১ (Day 1-7)</strong><br><em>Foundation</em></td>
          <td>
            • Analytics ও UTM সেটআপ<br>
            • Reddit (r/SideProject) ভ্যালু পোস্ট<br>
            • Twitter-এ ফ্রি অডিট অফার
          </td>
          <td>
            • ২০-৩০ ফ্রি সাইনআপ<br>
            • ৫০+ অ্যাপ ট্র্যাকিং ডেটা
          </td>
          <td><span class="kpi-pill kpi-high">HIGH</span></td>
        </tr>
        <tr>
          <td><strong>সপ্তাহ ২ (Day 8-14)</strong><br><em>Outreach</em></td>
          <td>
            • প্রতিদিন ১০ জন ASO স্পেশালিস্টকে LinkedIn DM<br>
            • ৩টি কেস স্টাডি টুইট থ্রেড<br>
            • Product Hunt লঞ্চ অ্যাসেট তৈরি
          </td>
          <td>
            • ৫০+ টোটাল সাইনআপ<br>
            • ১০ জন এজেন্সি ট্রায়াল
          </td>
          <td><span class="kpi-pill kpi-high">HIGH</span></td>
        </tr>
        <tr>
          <td><strong>সপ্তাহ ৩ (Day 15-21)</strong><br><em>The Big Launch</em></td>
          <td>
            • Product Hunt লাইভ লঞ্চ (মঙ্গলবার)<br>
            • Hacker News 'Show HN' পোস্ট<br>
            • লাইভ লঞ্চে আসা ইউজারদের সাপোর্ট
          </td>
          <td>
            • ১৫০+ টোটাল ভিজিটর/দিন<br>
            • Top 5 Product of the Day
          </td>
          <td><span class="kpi-pill kpi-high">CRITICAL</span></td>
        </tr>
        <tr>
          <td><strong>সপ্তাহ ৪ (Day 22-30)</strong><br><em>Monetization</em></td>
          <td>
            • সব ফ্রি ইউজারকে ৫০% আর্লি বার্ড ইমেল পাঠানো<br>
            • এজেন্সিগুলোর সাথে ফলো-আপ কল/মেসেজ<br>
            • পেইড প্রো সাবস্ক্রিপশন কনভার্শন
          </td>
          <td>
            • ৫-১০ জন পেইড Pro কাস্টমার<br>
            • $১০০ - $২৫০ MRR শুরু
          </td>
          <td><span class="kpi-pill kpi-med">REVENUE</span></td>
        </tr>
      </tbody>
    </table>

    <div class="card card-highlight" style="margin-top: 14px;">
      <div class="card-heading">🎯 আপনার চূড়ান্ত সাফল্যের মন্ত্র:</div>
      <p>মার্কেটিংয়ে কোনো জটিল রহস্য নেই — এটি প্রতিদিনের <strong>১৫-২০ মিনিটের ধারাবাহিকতা</strong>। আপনি যদি প্রথম ৩০ দিন প্রতিদিন মাত্র ৩ জন মানুষকে পার্সোনাল মেসেজ পাঠান এবং প্রতি সপ্তাহে ২টি ভ্যালু পোস্ট দেন, তবে ৩০ দিন পর আপনার কাছে ১০০+ ইউজার এবং নিয়মিত পেইড সাবস্ক্রিপশন থাকবে।</p>
    </div>

    <div class="footer-bar">
      <strong>AppRadar Executive Growth Playbook</strong> • Confidential & Proprietary Strategy Document.
    </div>
  </div>

</body>
</html>
`;

const htmlFilePath = path.join(__dirname, 'pro_marketing_playbook.html');
const pdfFilePath = path.join(__dirname, 'AppRadar_Pro_Marketing_Playbook.pdf');

fs.writeFileSync(htmlFilePath, htmlContent, 'utf8');
console.log('Professional HTML playbook written.');

const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const command = '"' + edgePath + '" --headless=new --disable-gpu --print-to-pdf="' + pdfFilePath + '" --no-pdf-header-footer "' + htmlFilePath + '"';

try {
  console.log('Compiling Master PDF...');
  execSync(command);
  console.log('Success! Master PDF generated at:', pdfFilePath);
} catch (err) {
  console.error('Error generating PDF:', err);
}
