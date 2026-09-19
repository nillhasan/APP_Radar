import OpenAI from "openai";
import { createClient } from "@supabase/supabase-js";
import { Resend } from "resend";

const apps = [
  {
    name: "AI Note Taker",
    category: "Productivity",
    rating: 4.7,
    reviews: 8200,
    growth: 180,
    rankingSignal: 90,
    revenueSignal: 72,
    marketSignal: 82,
    description: "AI-powered meeting transcription, summaries and action items."
  },
  {
    name: "Calorie AI",
    category: "Health & Fitness",
    rating: 4.6,
    reviews: 12000,
    growth: 120,
    rankingSignal: 82,
    revenueSignal: 75,
    marketSignal: 78,
    description: "AI-assisted meal tracking and calorie estimation."
  },
  {
    name: "PDF AI Assistant",
    category: "Productivity",
    rating: 4.5,
    reviews: 6200,
    growth: 95,
    rankingSignal: 78,
    revenueSignal: 70,
    marketSignal: 76,
    description: "Chat with PDFs and extract useful information with AI."
  }
];

function score(a: typeof apps[number]) {
  const growth = Math.min(a.growth / 2, 100);
  const review = Math.min(a.reviews / 100, 100);
  return Math.round(
    growth * 0.30 +
    a.revenueSignal * 0.25 +
    a.rankingSignal * 0.20 +
    review * 0.15 +
    a.marketSignal * 0.10
  );
}

async function main() {
  const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  const scored = apps.map(a => ({ ...a, opportunityScore: score(a) }))
    .sort((a, b) => b.opportunityScore - a.opportunityScore);

  const top = scored.slice(0, 5);

  const prompt = `You are AppRadar, an app market intelligence analyst.
Analyze these apps. Do not invent metrics. Separate observed facts from interpretation.
Return concise JSON with an array called analyses. Each item must contain:
name, summary, target_user, core_features, monetization, user_pain_points,
build_opportunity, mvp_features, risks.

DATA:
${JSON.stringify(top, null, 2)}`;

  const response = await openai.responses.create({
    model: "gpt-5-mini",
    input: prompt
  });

  const report = response.output_text;
  console.log("Top opportunities:", top);
  console.log("AI analysis:", report);

  // Production step:
  // 1. Upsert data into Supabase.
  // 2. Render HTML email.
  // 3. Send through Resend.
  //
  // Credentials are intentionally read from environment variables.
  if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_ROLE_KEY) {
    const supabase = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );
    await supabase.from("apps").upsert(
      top.map(a => ({
        name: a.name,
        category: a.category,
        description: a.description,
        rating: a.rating,
        review_count: a.reviews,
        created_at: new Date().toISOString()
      })),
      { onConflict: "name" }
    );
  }

  if (process.env.RESEND_API_KEY && process.env.REPORT_TO_EMAIL && process.env.REPORT_FROM_EMAIL) {
    const resend = new Resend(process.env.RESEND_API_KEY);
    await resend.emails.send({
      from: process.env.REPORT_FROM_EMAIL,
      to: process.env.REPORT_TO_EMAIL,
      subject: "🚀 AppRadar — Daily App Opportunity Report",
      html: `<h1>AppRadar</h1><h2>Today's Top Opportunities</h2>
        ${top.map(a => `<h3>${a.name} — ${a.opportunityScore}/100</h3>
        <p>${a.category} · ${a.rating} ⭐ · ${a.reviews} reviews · +${a.growth}% growth</p>`).join("")}
        <hr/><pre>${report.replace(/</g, "&lt;").replace(/>/g, "&gt;")}</pre>`
    });
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
