<script>
  import { pinyin } from 'pinyin-pro';

  /** Converts raw text input into structured sentence groups based on custom punctuation/quote logic */
  function parseTextToPinyinGroups(text) {
    if (!text.trim()) return [];

    // FIX 1: Added the full-width comma '，' that was missing in the previous version
    const SENTENCE_PUNCT_REGEX = /[,，.。!！?？;；:：]/;

    // Identify paired wrapper characters (quotes, brackets, parentheses)
    const PAIRS = {
      '(': ')', '（': '）',
      '[': ']', '【': '】',
      '{': '}', '《': '》',
      '"': '"', "'": "'",
      '“': '”', '‘': '’'
    };
    const OPENERS = new Set(Object.keys(PAIRS));
    const CLOSERS = new Set(Object.values(PAIRS));

    const chunks = [];
    let currentChunk = '';
    const stack = []; // Track active quotes/parentheses

    // Helper: append complete chunk to results with Pinyin metadata
    function pushChunk(str) {
      const trimmed = str.trim();
      if (!trimmed) return;

      const chars = Array.from(trimmed);
      const pinyinList = pinyin(trimmed, { 
        type: 'array', 
        toneType: 'symbol' 
        // FIX 2: Removed nonZh: 'consecutive' 
        // Consecutive punctuation like `)，` would group together in pinyin-pro
        // and break the 1-to-1 mapping length between `chars` and `pinyinList`.
      });

      chunks.push(
        chars.map((char, index) => ({
          char,
          pinyin: pinyinList[index] || ''
        }))
      );
    }

    // Process character by character
    for (let i = 0; i < text.length; i++) {
      const char = text[i];
      const currentEnclosure = stack[stack.length - 1];

      if (OPENERS.has(char)) {
        // Handle matching quotes/brackets
        if (currentEnclosure && PAIRS[currentEnclosure] === char) {
          stack.pop();
          currentChunk += char;
        } else {
          stack.push(char);
          currentChunk += char;
        }
      } else if (CLOSERS.has(char)) {
        if (currentEnclosure && PAIRS[currentEnclosure] === char) {
          stack.pop();
        }
        currentChunk += char;
      } else if (SENTENCE_PUNCT_REGEX.test(char)) {
        // Punctuation attaches to current chunk, then triggers split
        currentChunk += char;
        pushChunk(currentChunk);
        currentChunk = '';
      } else {
        currentChunk += char;
      }
    }

    // Push any remaining text
    if (currentChunk) {
      pushChunk(currentChunk);
    }

    return chunks;
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

  async function copyPinyin() {
    const fullPinyin = formatFullPinyin(sentenceGroups);
    await navigator.clipboard.writeText(fullPinyin);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }
</script>

<main class="max-w-lg mx-auto my-12 p-8 bg-slate-900/90 backdrop-blur-md rounded-2xl shadow-2xl shadow-black/50 border border-slate-800 font-sans text-slate-100">

  <!-- FORM SECTION -->
  <form onsubmit={handleSubmit} class="space-y-5">
    <div class="flex flex-col gap-2">
      <div class="flex justify-between items-center">
        <label for="chinese-text" class="text-xs font-bold uppercase tracking-wider text-slate-400">
          Enter Chinese Characters
        </label>
        <span class="text-xs text-slate-500">{charCount} chars</span>
      </div>

      <div class="relative">
        <textarea 
          id="chinese-text" 
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
              <div class="flex flex-wrap items-center gap-x-1">
                {#each group as item}
                  <span class="text-2xl font-bold text-slate-100">{item.char}</span>
                {/each}
              </div>
            </div>

            <!-- Pinyin Segment -->
            <div>
              <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1">Pinyin</h4>
              <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
                {#each group as item}
                  <span class="text-base font-medium text-slate-300">{item.pinyin}</span>
                {/each}
              </div>
            </div>
          </div>
        {/each}
      </div>

    </div>
  {/if}
</main>
