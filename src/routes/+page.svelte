<script>
  import { pinyin } from 'pinyin-pro';

  // Input state
  let textInput = $state('你好世界');
  
  // Submitted paired data state
  let pairs = $state([]);
  let submitted = $state(false);

  // Palette of Tailwind border colors to cycle through
  const colorPalette = [
    'border-blue-500 text-blue-600',
    'border-emerald-500 text-emerald-600',
    'border-amber-500 text-amber-600',
    'border-purple-500 text-purple-600',
    'border-rose-500 text-rose-600',
    'border-indigo-500 text-indigo-600',
    'border-teal-500 text-teal-600'
  ];

  function handleSubmit(e) {
    e.preventDefault();
    if (!textInput.trim()) return;

    // Convert string into arrays of chars and pinyin syllables (tone accents)
    const chars = Array.from(textInput);
    const pinyinList = pinyin(textInput, { 
      type: 'array', 
      toneType: 'symbol', 
      nonZh: 'consecutive' 
    });

    // Map each char to its pinyin and assign a cycling color class
    pairs = chars.map((char, index) => {
      const colorClass = colorPalette[index % colorPalette.length];
      return {
        char,
        pinyin: pinyinList[index] || '',
        colorClass
      };
    });

    submitted = true;
  }
</script>

<main class="max-w-md mx-auto my-8 p-6 bg-white rounded-xl shadow-md space-y-6 border border-slate-100">
  <h2 class="text-xl font-bold text-slate-800">Chinese to Pinyin Converter</h2>

  <!-- Form Section -->
  <form onsubmit={handleSubmit} class="space-y-4">
    <div class="flex flex-col gap-1.5">
      <label for="chinese-text" class="text-sm font-medium text-slate-700">
        Enter Chinese Characters:
      </label>
      <input 
        id="chinese-text" 
        type="text" 
        bind:value={textInput} 
        placeholder="Type Hanzi here..." 
        class="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition"
      />
    </div>

    <button 
      type="submit" 
      class="w-full py-2.5 px-4 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg shadow-sm transition active:scale-[0.99]"
    >
      Submit
    </button>
  </form>

  <!-- Output Section (only shows after submit) -->
  {#if submitted}
    <div class="pt-4 border-t border-slate-200 space-y-4">
      <!-- Chinese Characters Field (no spacing between chars) -->
      <div>
        <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-500 mb-2">Chinese</h3>
        <div class="flex flex-wrap items-center">
          {#each pairs as item}
            <span class="text-2xl font-semibold border-b-4 pb-0.5 {item.colorClass}">
              {item.char}
            </span>
          {/each}
        </div>
      </div>

      <!-- Pinyin Field (spaced by words/syllables) -->
      <div>
        <h3 class="text-xs font-semibold uppercase tracking-wider text-slate-500 mb-2">Pinyin</h3>
        <div class="flex flex-wrap items-center gap-x-2 gap-y-1">
          {#each pairs as item}
            <span class="text-lg font-medium border-b-2 pb-0.5 {item.colorClass}">
              {item.pinyin}
            </span>
          {/each}
        </div>
      </div>
    </div>
  {/if}
</main>
