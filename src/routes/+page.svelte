<script>
  import { pinyin } from 'pinyin-pro';

  /** Converts raw text input into structured sentence groups based on custom punctuation/quote/emoji logic */
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

  // Regex matching standard punctuation or Unicode Emojis
  const SENTENCE_PUNCT_REGEX = /[,，.。!！?？;；:：]|\p{Extended_Pictographic}/u;

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
  const stack = [];

  function pushChunk(str) {
    const trimmed = str.trim();
    if (!trimmed) return;

    const chars = Array.from(trimmed);
    const pinyinList = pinyin(trimmed, { 
      type: 'array', 
      toneType: 'symbol' 
    });

    chunks.push(
      chars.map((char, index) => ({
        char,
        pinyin: pinyinList[index] || ''
      }))
    );
  }

  const characters = Array.from(text);

  for (let i = 0; i < characters.length; i++) {
    const char = characters[i];
    const currentEnclosure = stack[stack.length - 1];

    if (OPENERS.has(char)) {
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
      currentChunk += char;
      pushChunk(currentChunk);
      currentChunk = '';
    } else {
      currentChunk += char;
    }
  }

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
              <p class="text-base font-medium text-slate-300 break-words leading-relaxed">
                {#each group as item}
                  {#if item.pinyin}
                    <span>{item.pinyin}&nbsp;</span>
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
