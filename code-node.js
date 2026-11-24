// n8n Code node: "Parse AI reply"
// Mode: Run Once for Each Item. Sits between "Message a model" (Gemini) and the next step.
// Turns Gemini's text reply into clean fields, with safe defaults if the AI misbehaves.

// 1. Find the AI's text. The Gemini node returns { content: { parts: [{ text }] } };
//    other AI nodes use `text` or `output`, so those are checked as fallbacks.
const content = $json.content;
const parts = Array.isArray(content) ? content : (content?.parts ?? []);
const raw = parts.map((p) => p.text ?? '').join('') || $json.text || $json.output || '';

// 2. Parse it. Strip ```json fences, then take only the {...} part in case the
//    model added words around it. Any failure leaves `ai` empty -> defaults below.
let ai = {};
try {
  const cleaned = String(raw).replace(/```json|```/g, '');
  const start = cleaned.indexOf('{');
  const end = cleaned.lastIndexOf('}');
  ai = JSON.parse(cleaned.slice(start, end + 1));
} catch (e) {
  ai = {};
}

// 3. Original form fields, straight from the Webhook node (not from the AI).
const lead = $('Webhook').item.json.body ?? {};

// 4. Validate every AI field before trusting it.
const categories = ['sales', 'support', 'spam'];
const urgency = Math.round(Number(ai.urgency));

return {
  json: {
    time: new Date().toISOString(),
    name: lead.name ?? '',
    email: lead.email ?? '',
    message: lead.message ?? '',
    category: categories.includes(ai.category) ? ai.category : 'support',
    urgency: urgency >= 1 && urgency <= 5 ? urgency : 3,
    summary: ai.summary || lead.message || '(empty message)',
    ai_parsed: Object.keys(ai).length > 0,
  },
};
