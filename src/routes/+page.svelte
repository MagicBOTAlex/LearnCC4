<script>
  import { pinyin } from 'pinyin-pro';

  // Input state
  let textInput = $state('你好世界');
  
  // Submitted paired data state
  let pairs = $state([]);
  let submitted = $state(false);
  let copied = $state(false);

  // Clean Palette of Tailwind accent colors adapted for Dark Mode
  const colorPalette = [
    { border: 'border-blue-500/60', bg: 'bg-blue-950/40' },
    { border: 'border-emerald-500/60', bg: 'bg-emerald-950/40' },
    { border: 'border-amber-500/60', bg: 'bg-amber-950/40' },
    { border: 'border-purple-500/60', bg: 'bg-purple-950/40' },
    { border: 'border-rose-500/60', bg: 'bg-rose-950/40' },
    { border: 'border-indigo-500/60', bg: 'bg-indigo-950/40' },
    { border: 'border-teal-500/60', bg: 'bg-teal-950/40' }
  ];

  function handleSubmit(e) {
    if (e) e.preventDefault();
    if (!textInput.trim()) return;

    // Convert string into arrays of chars and pinyin syllables
    const chars = Array.from(textInput);
    const pinyinList = pinyin(textInput, { 
      type: 'array', 
      toneType: 'symbol', 
      nonZh: 'consecutive' 
    });

    // Map each char to its pinyin and assign a cycling color theme
    pairs = chars.map((char, index) => {
      const colorScheme = colorPalette[index % colorPalette.length];
      return {
        char,
        pinyin: pinyinList[index] || '',
        ...colorScheme
      };
    });

    submitted = true;
  }

  function handleKeyDown(e) {
    // Submit on Cmd+Enter or Ctrl+Enter
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      handleSubmit(e);
    }
  }

  function copyPinyin() {
    const fullPinyin = pairs.map(p => p.pinyin).join(' ');
    navigator.clipboard.writeText(fullPinyin);
    copied = true;
    setTimeout(() => (copied = false), 2000);
  }
</script>

<main class="max-w-lg mx-auto my-12 p-8 bg-slate-900/90 backdrop-blur-md rounded-2xl shadow-2xl shadow-black/50 border border-slate-800 font-sans text-slate-100">

  <!-- Form Section -->
  <form onsubmit={handleSubmit} class="space-y-5">
    <div class="flex flex-col gap-2">
      <div class="flex justify-between items-center">
        <label for="chinese-text" class="text-xs font-bold uppercase tracking-wider text-slate-400">
          Enter Chinese Characters
        </label>
        <span class="text-xs text-slate-500">{textInput.length} chars</span>
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

  <!-- Output Section -->
  {#if submitted}
    <div class="mt-8 pt-6 border-t border-slate-800 space-y-6 animate-in fade-in duration-300">
      <!-- Toolbar Header -->
      <div class="flex items-center justify-between">
        <h3 class="text-xs font-bold uppercase tracking-wider text-slate-400">Result Cards</h3>
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

      <!-- Separate Text Flows -->
      <div class="p-4 bg-slate-950/50 rounded-xl space-y-4 border border-slate-800/80">
        <!-- Chinese Characters Field -->
        <div>
          <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5">Hanzi Flow</h4>
          <div class="flex flex-wrap items-center">
            {#each pairs as item}
              <span class="text-2xl font-bold border-b-2 pb-0.5 {item.border} text-slate-100">
                {item.char}
              </span>
            {/each}
          </div>
        </div>

        <!-- Pinyin Field -->
        <div>
          <h4 class="text-[10px] font-bold uppercase tracking-wider text-slate-500 mb-1.5">Pinyin Flow</h4>
          <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
            {#each pairs as item}
              <span class="text-base font-medium border-b-2 pb-0.5 {item.border} {item.text}">
                {item.pinyin}
              </span>
            {/each}
          </div>
        </div>
      </div>
    </div>
  {/if}
</main>
