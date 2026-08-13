<script>
  import { pinyin } from 'pinyin-pro';

  /** Converts raw text input into structured sentence groups based on custom punctuation/quote/emoji/space logic */
/** Converts raw text input into structured sentence groups based on custom punctuation/quote/emoji/space/link logic */
function parseTextToPinyinGroups(text) {
  if (!text.trim()) return [];

  // Check overall length condition: if less than 5 characters, do not split
  if (Array.from(text).length < 5) {
    return [
      Array.from(text).map((char) => {
        const pinyinList = pinyin(char, { type: 'array', toneType: 'symbol' });
        return { char, pinyin: pinyinList[0] || '' };
      })
    ];
  }

  // Regex to match URLs (http, https, or standard c.tb.cn-style domain links)
  const URL_REGEX = /(https?:\/\/[^\s\u3000,\uFF0C\u3002!！?？;；:：\u201C\u201D"'\u3010\u3011\uFF08\uFF09]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?::\d+)?(?:\/[^\s\u3000,\uFF0C\u3002!！?？;；:：]*)?)/g;

  // Regex matching standard punctuation, spaces (\s, \u3000), or Unicode Emojis
  const SENTENCE_PUNCT_REGEX = /[,，.。!！?？;；:：\s\u3000]|\p{Extended_Pictographic}/u;

  const PAIRS = {
    '(': ')', '（': '）',
    '[': ']', '【': '】',
    '{': '}', '《': '》',
    '"': '"', "'": "'",
    '“': '”', '‘': '’'
  };
  const OPENERS = new Set(Object.keys(PAIRS));
  const CLOSERS = new Set(Object.values(PAIRS));

  // --- Step 1: Tokenize text into URLs and non-URL text blocks ---
  const tokens = [];
  let lastIdx = 0;
  let match;

  while ((match = URL_REGEX.exec(text)) !== null) {
    if (match.index > lastIdx) {
      tokens.push({ type: 'text', content: text.slice(lastIdx, match.index) });
    }
    tokens.push({ type: 'url', content: match[0] });
    lastIdx = URL_REGEX.lastIndex;
  }
  if (lastIdx < text.length) {
    tokens.push({ type: 'text', content: text.slice(lastIdx) });
  }

  // --- Step 2: Helper to turn text into Pinyin items ---
  function createPinyinItems(str) {
    const chars = Array.from(str);
    const pinyinList = pinyin(str, { type: 'array', toneType: 'symbol' });

    return chars.map((char, index) => ({
      char,
      pinyin: pinyinList[index] || ''
    }));
  }

  // --- Step 3: Segment tokens while handling delimiters and quotes ---
  const chunks = [];
  let currentGroup = [];
  const stack = [];

  for (const token of tokens) {
    if (token.type === 'url') {
      // Treat the whole URL as a single block (no pinyin for URL characters)
      currentGroup.push({
        char: token.content,
        pinyin: ''
      });
      // A URL acts as a distinct segment bound
      if (stack.length === 0 && currentGroup.length > 0) {
        chunks.push(currentGroup);
        currentGroup = [];
      }
      continue;
    }

    // Process regular text character by character
    const characters = Array.from(token.content);
    for (let i = 0; i < characters.length; i++) {
      const char = characters[i];
      const currentEnclosure = stack[stack.length - 1];

      if (OPENERS.has(char)) {
        if (currentEnclosure && PAIRS[currentEnclosure] === char) {
          stack.pop();
        } else {
          stack.push(char);
        }
        currentGroup.push(...createPinyinItems(char));
      } else if (CLOSERS.has(char)) {
        if (currentEnclosure && PAIRS[currentEnclosure] === char) {
          stack.pop();
        }
        currentGroup.push(...createPinyinItems(char));
      } else if (SENTENCE_PUNCT_REGEX.test(char)) {
        currentGroup.push(...createPinyinItems(char));
        
        // If not inside quotes/brackets, finish current sentence chunk
        if (stack.length === 0) {
          if (currentGroup.length > 0) {
            chunks.push(currentGroup);
            currentGroup = [];
          }
        }
      } else {
        currentGroup.push(...createPinyinItems(char));
      }
    }
  }

  if (currentGroup.length > 0) {
    chunks.push(currentGroup);
  }

  // Filter out any empty chunks resulting from consecutive delimiters
  return chunks.filter(group => group.some(item => item.char.trim()));
}

  /** Flattens sentence groups into a single formatted Pinyin string */
  function formatFullPinyin(groups) {
    return groups
      .flatMap(group => group.map(p => p.pinyin))
      .join(' ');
  }

  // --- 2. STATE MANAGEMENT ---
  let textInput = $state('');
  let sentenceGroups = $state([]);
  let submitted = $state(false);
  let copied = $state(false);
  let textareaRef = $state(null);

  // Derived state
  const charCount = $derived(textInput.length);

  // --- 3. EVENT HANDLERS & ACTIONS ---
  function handleSubmit(e) {
    if (e) e.preventDefault();
    if (!textInput.trim()) return;

    sentenceGroups = parseTextToPinyinGroups(textInput);
    submitted = true;
  }

  function handleKeyDown(e) {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handleSubmit(e);
    }
  }

  function handleClear() {
    textInput = '';
    sentenceGroups = [];
    submitted = false;
    textareaRef?.focus();
  }

  async function copyPinyin() {
    const fullPinyin = formatFullPinyin(sentenceGroups);
    await navigator.clipboard.writeText(fullPinyin);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }

  // Updated: Paste & Override with Auto-Submit
  async function pasteAndOverride() {
    try {
      const text = await navigator.clipboard.readText();
      textInput = text;
      handleSubmit(); // Auto-submits the form immediately after pasting
    } catch (err) {
      console.error('Failed to read clipboard contents: ', err);
    }
  }
</script>

<main class="max-w-lg mx-auto my-12 p-8 bg-slate-900/90 backdrop-blur-md rounded-2xl shadow-2xl shadow-black/50 border border-slate-800 font-sans text-slate-100">

  <!-- FORM SECTION -->
  <form onsubmit={handleSubmit} class="space-y-5">
    <div class="flex flex-col gap-2">
      <div class="flex justify-between items-end mb-1">
        <label for="chinese-text" class="text-xs font-bold uppercase tracking-wider text-slate-400">
          Enter Chinese Characters
        </label>
        <div class="flex items-center gap-2">
          <button 
            type="button" 
            onclick={handleClear}
            disabled={!textInput}
            class="text-[10px] uppercase font-bold tracking-wider text-slate-400 hover:text-slate-200 bg-slate-800 hover:bg-slate-700 disabled:opacity-40 disabled:cursor-not-allowed px-2.5 py-1 rounded-md transition-colors border border-slate-700/60"
          >
            Clear
          </button>
          <button 
            type="button" 
            onclick={pasteAndOverride}
            class="text-[10px] uppercase font-bold tracking-wider text-indigo-400 hover:text-indigo-300 bg-indigo-500/10 hover:bg-indigo-500/20 px-2.5 py-1 rounded-md transition-colors border border-indigo-500/20"
          >
            Paste & Override
          </button>
          <span class="text-xs text-slate-500 ml-1">{charCount} chars</span>
        </div>
      </div>

      <div class="relative">
        <textarea 
          id="chinese-text" 
          bind:this={textareaRef}
          rows="3"
          bind:value={textInput} 
          onkeydown={handleKeyDown}
          placeholder="Type Hanzi here..." 
          class="w-full px-4 py-3 bg-slate-950/60 border border-slate-800 rounded-xl text-slate-100 placeholder-slate-500 text-base focus:bg-slate-950 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 focus:border-indigo-500 transition-all duration-200 resize-y min-h-[5rem]"
        ></textarea>
      </div>
    </div>

    <button 
      type="submit" 
      class="w-full py-3 px-5 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-500 hover:to-violet-500 text-white font-semibold rounded-xl shadow-lg shadow-indigo-950/50 transition-all duration-150 active:scale-[0.98] cursor-pointer flex items-center justify-center gap-2"
    >
      <span>Convert to Pinyin</span>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14 5l7 7m0 0l-7 7m7-7H3" />
      </svg>
    </button>
  </form>

  <!-- OUTPUT SECTION -->
  {#if submitted}
    <div class="mt-8 pt-6 border-t border-slate-800 space-y-6 animate-in fade-in duration-300">
      
      <!-- Toolbar Header -->
      <div class="flex items-center justify-between">
        <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400">Result Sentences</h3>
        <button 
          type="button" 
          onclick={copyPinyin}
          class="text-xs font-semibold text-slate-300 hover:text-white bg-slate-800 hover:bg-slate-700/80 px-3 py-1.5 rounded-lg border border-slate-700/60 transition-colors duration-150 flex items-center gap-1.5"
        >
          {#if copied}
            <span class="text-emerald-400">✓ Copied</span>
          {:else}
            <span>Copy Pinyin</span>
          {/if}
        </button>
      </div>

      <!-- Segmented Sentence Blocks -->
<div class="space-y-4">
  {#each sentenceGroups as group, idx}
    <div class="p-4 bg-slate-950/50 rounded-xl space-y-3 border border-slate-800/80">
      <!-- Hanzi Segment -->
      <div>
        <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">Sentence {idx + 1} - Hanzi</h4>
        <p class="text-2xl font-bold text-slate-100 break-words leading-relaxed">
          {#each group as item}{item.char}{/each}
        </p>
      </div>

      <!-- Pinyin Segment -->
      <div>
        <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">Pinyin</h4>
        <p class="text-base font-medium text-slate-300 break-normal leading-relaxed">
          {#each group as item}
            {#if item.pinyin}
              <!-- inline-block & whitespace-nowrap keep the whole Pinyin syllable together -->
              <span class="inline-block whitespace-nowrap">{item.pinyin}&nbsp;</span>
            {/if}
          {/each}
        </p>
      </div>
    </div>
  {/each}
</div>

    </div>
  {/if}
</main>
