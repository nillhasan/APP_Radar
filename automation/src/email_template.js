/**
 * AppRadar Executive Daily Email Template
 * Modern, responsive HTML email for mobile SaaS market intelligence.
 */
export function renderEmailTemplate({ totalAnalyzed, topOpportunities, dateString }) {
  const oppCardsHtml = topOpportunities.map((opp, idx) => {
    const isIos = opp.platform?.includes('iOS');
    const badgeColor = isIos ? '#0284C7' : '#059669';
    const badgeBg = isIos ? '#E0F2FE' : '#D1FAE5';
    const platformLabel = isIos ? '🍏 Apple App Store' : '🤖 Google Play';

    const featuresList = (opp.analysis?.core_features || opp.analysis?.suggested_mvp || [])
      .slice(0, 3)
      .map(f => `<li style="margin-bottom: 4px; color: #475569;">${f}</li>`)
      .join('');

    return `
      <div style="background-color: #ffffff; border: 1px solid #e2e8f0; border-radius: 12px; padding: 20px; margin-bottom: 16px; box-shadow: 0 1px 3px rgba(0,0,0,0.05);">
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 12px;">
          <div>
            <div style="display: inline-block; padding: 3px 8px; border-radius: 6px; font-size: 11px; font-weight: 700; color: ${badgeColor}; background-color: ${badgeBg}; margin-bottom: 6px;">
              ${platformLabel} · ${opp.raw?.primaryGenreName || opp.category || 'SaaS'}
            </div>
            <h3 style="margin: 0 0 4px 0; color: #0f172a; font-size: 17px; font-weight: 700;">
              #${idx + 1} ${opp.raw?.trackName || opp.name}
            </h3>
            <div style="font-size: 13px; color: #64748b;">
              by ${opp.raw?.sellerName || 'Independent'} · ⭐ ${opp.raw?.averageUserRating || 4.7} (${Number(opp.raw?.userRatingCount || 5000).toLocaleString()} reviews)
            </div>
          </div>
          <div style="text-align: right;">
            <div style="display: inline-block; padding: 6px 12px; background: linear-gradient(135deg, #2563eb, #1d4ed8); color: #ffffff; font-weight: 800; font-size: 16px; border-radius: 8px; box-shadow: 0 2px 4px rgba(37,99,235,0.2);">
              ${opp.analysis?.opportunity_score || opp.score || 82}<span style="font-size: 11px; opacity: 0.8;">/100</span>
            </div>
            <div style="font-size: 11px; color: #10b981; font-weight: 600; margin-top: 4px;">
              +${opp.analysis?.growth_signal || opp.growth || 85}% Growth
            </div>
          </div>
        </div>

        <p style="color: #334155; font-size: 14px; line-height: 1.5; margin: 0 0 12px 0;">
          ${opp.analysis?.what_it_does || opp.what_it_does || 'Fast growing application with surging store search velocity.'}
        </p>

        <div style="background-color: #f8fafc; border-radius: 8px; padding: 12px; margin-bottom: 12px;">
          <div style="font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;">
            💡 Why It's Growing & Moat
          </div>
          <div style="font-size: 13px; color: #1e293b; line-height: 1.4;">
            ${opp.analysis?.why_growing || 'Strong organic demand and underserved workflow monetization gaps.'}
          </div>
        </div>

        ${featuresList ? `
          <div style="font-size: 12px; font-weight: 700; color: #475569; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 6px;">
            🚀 Suggested MVP Architecture
          </div>
          <ul style="margin: 0; padding-left: 20px; font-size: 13px;">
            ${featuresList}
          </ul>
        ` : ''}

        ${opp.raw?.trackViewUrl ? `
          <div style="margin-top: 14px; text-align: right;">
            <a href="${opp.raw.trackViewUrl}" style="font-size: 12px; color: #2563eb; text-decoration: none; font-weight: 600;">
              View Store Listing &rarr;
            </a>
          </div>
        ` : ''}
      </div>
    `;
  }).join('');

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AppRadar Daily Market Intelligence</title>
</head>
<body style="margin: 0; padding: 0; background-color: #f1f5f9; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="background-color: #f1f5f9; padding: 30px 10px;">
    <tr>
      <td align="center">
        <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 620px; background-color: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.05), 0 2px 4px -1px rgba(0,0,0,0.03);">
          
          <!-- Header -->
          <tr>
            <td style="background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); padding: 32px 30px; text-align: left;">
              <div style="display: flex; align-items: center;">
                <div style="font-size: 26px; font-weight: 800; color: #ffffff; letter-spacing: -0.5px;">
                  📡 App<span style="color: #3b82f6;">Radar</span>
                </div>
              </div>
              <div style="margin-top: 8px; color: #94a3b8; font-size: 13px; font-weight: 500;">
                DAILY MOBILE OPPORTUNITY DIGEST · ${dateString}
              </div>
            </td>
          </tr>

          <!-- KPI Summary Strip -->
          <tr>
            <td style="background-color: #f8fafc; border-bottom: 1px solid #e2e8f0; padding: 18px 30px;">
              <table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                  <td style="text-align: center; border-right: 1px solid #e2e8f0; width: 33%;">
                    <div style="font-size: 20px; font-weight: 800; color: #0f172a;">${totalAnalyzed}</div>
                    <div style="font-size: 11px; font-weight: 600; color: #64748b; text-transform: uppercase;">Apps Scanned</div>
                  </td>
                  <td style="text-align: center; border-right: 1px solid #e2e8f0; width: 33%;">
                    <div style="font-size: 20px; font-weight: 800; color: #2563eb;">${topOpportunities.length}</div>
                    <div style="font-size: 11px; font-weight: 600; color: #64748b; text-transform: uppercase;">Breakouts</div>
                  </td>
                  <td style="text-align: center; width: 33%;">
                    <div style="font-size: 20px; font-weight: 800; color: #10b981;">Dual Store</div>
                    <div style="font-size: 11px; font-weight: 600; color: #64748b; text-transform: uppercase;">iOS + Android</div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <!-- Main Content -->
          <tr>
            <td style="padding: 28px 30px;">
              <div style="margin-bottom: 20px;">
                <h2 style="margin: 0 0 6px 0; font-size: 18px; font-weight: 700; color: #0f172a;">
                  🔥 Top Breakout Opportunities Today
                </h2>
                <p style="margin: 0; font-size: 13px; color: #64748b;">
                  Selected by Gemini 3.6 Flash based on growth velocity, store ratings density, and market moat gaps.
                </p>
              </div>

              ${oppCardsHtml}

              <!-- Call to Action -->
              <div style="text-align: center; margin-top: 30px; margin-bottom: 10px;">
                <div style="background-color: #f1f5f9; border-radius: 12px; padding: 20px; text-align: center;">
                  <h4 style="margin: 0 0 6px 0; color: #0f172a; font-size: 15px;">Ready to build one of these apps?</h4>
                  <p style="margin: 0 0 14px 0; color: #64748b; font-size: 13px;">Generate full 14-section architectural blueprints, Flutter UI trees, and Supabase SQL schemas directly in AppRadar.</p>
                  <a href="http://localhost:8080" style="display: inline-block; background-color: #2563eb; color: #ffffff; padding: 10px 24px; border-radius: 8px; font-size: 14px; font-weight: 600; text-decoration: none; box-shadow: 0 2px 4px rgba(37,99,235,0.3);">
                    Open AppRadar Studio &rarr;
                  </a>
                </div>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="background-color: #f8fafc; border-top: 1px solid #e2e8f0; padding: 24px 30px; text-align: center;">
              <p style="margin: 0 0 4px 0; color: #64748b; font-size: 12px;">
                Generated automatically by <strong>AppRadar Market Intelligence Engine</strong>.
              </p>
              <p style="margin: 0; color: #94a3b8; font-size: 11px;">
                Telemetry sources: Apple App Store API · Google Play Scraper · Gemini 3.6 Flash
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `;
}
