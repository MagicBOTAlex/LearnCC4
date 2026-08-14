<script>
  import { pinyin } from 'pinyin-pro';

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
        currentGroup.push({
          char: token.content,
          pinyin: ''
        });
        if (stack.length === 0 && currentGroup.length > 0) {
          chunks.push(currentGroup);
          currentGroup = [];
        }
        continue;
      }

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

    return chunks.filter(group => group.some(item => item.char.trim()));
  }

  // --- STATE MANAGEMENT ---
  let textInput = $state('');
  let textareaRef = $state(null);

  // Derived state: automatically converts and updates whenever textInput changes
  const sentenceGroups = $derived(parseTextToPinyinGroups(textInput));
  const charCount = $derived(textInput.length);

  // --- ACTIONS ---
  function handleClear() {
    textInput = '';
    textareaRef?.focus();
  }

  async function pasteAndOverride() {
    try {
      const text = await navigator.clipboard.readText();
      textInput = text;
    } catch (err) {
      console.error('Failed to read clipboard contents: ', err);
    }
  }
</script>

<main class="max-w-lg mx-auto my-12 p-8 bg-slate-900/90 backdrop-blur-md rounded-2xl shadow-2xl shadow-black/50 border border-slate-800 font-sans text-slate-100">

  <!-- INPUT SECTION -->
  <div class="space-y-5">
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
        </div>
      </div>

      <div class="relative">
        <textarea 
          id="chinese-text" 
          bind:this={textareaRef}
          rows="3" 
          bind:value={textInput} 
          placeholder="Type Hanzi here..." 
          class="w-full px-4 py-3 bg-slate-950/60 border border-slate-800 rounded-xl text-slate-100 placeholder-slate-500 text-base focus:bg-slate-950 focus:outline-none focus:ring-2 focus:ring-indigo-500/40 focus:border-indigo-500 transition-all duration-200 resize-y min-h-[5rem]"
        ></textarea>
      </div>
    </div>
  </div>

  <!-- PINYIN OUTPUT SECTION -->
  {#if sentenceGroups.length > 0}
    <div class="mt-8 pt-6 border-t border-slate-800 space-y-4 animate-in fade-in duration-300">
      <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400">Pinyin Result</h3>

      <div class="space-y-4">
        {#each sentenceGroups as group, idx}
          <div class="p-4 bg-slate-950/50 rounded-xl space-y-2 border border-slate-800/80">
            <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500">Sentence {idx + 1}</h4>
            <div>
              <p class="text-base p-0 font-medium text-slate-300 break-normal leading-relaxed">
                {#each group as item}
                  {#if item.char}{item.char}{/if}
                {/each}
              </p>
            </div>
            <div>
              <p class="text-base font-medium text-slate-300 break-normal leading-relaxed">
                {#each group as item}
                  {#if item.pinyin}
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
