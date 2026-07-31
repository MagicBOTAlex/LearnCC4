<script>
  import { pinyin } from 'pinyin-pro';

  // Svelte 5 state (if using Svelte 4, use: let input = '你好世界';)
  let input = $state('你好世界');
  let toneType = $state('symbol'); // Options: 'symbol' (nǐ), 'num' (ni3), 'none' (ni)

  // Reactive derivation
  let pinyinResult = $derived(
    pinyin(input, { toneType, nonZh: 'consecutive' })
  );
</script>

<main class="container">
  <h2>Chinese to Pinyin Converter</h2>

  <div class="field">
    <label for="chinese-text">Enter Chinese Characters:</label>
    <input 
      id="chinese-text" 
      type="text" 
      bind:value={input} 
      placeholder="Type Hanzi here..." 
    />
  </div>

  <div class="field">
    <label for="tone-select">Tone Format:</label>
    <select id="tone-select" bind:value={toneType}>
      <option value="symbol">Tone Accent (nǐ hǎo)</option>
      <option value="num">Numbered Tone (ni3 hao3)</option>
      <option value="none">No Tone (ni hao)</option>
    </select>
  </div>

  <div class="output">
    <h3>Pinyin Output:</h3>
    <p class="result">{pinyinResult || '—'}</p>
  </div>
</main>

<style>
  .container {
    max-width: 450px;
    margin: 2rem auto;
    font-family: system-ui, sans-serif;
  }
  .field {
    margin-bottom: 1rem;
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
  }
  input, select {
    padding: 0.5rem;
    font-size: 1rem;
  }
  .output {
    margin-top: 1.5rem;
    padding: 1rem;
    background-color: #f4f4f5;
    border-radius: 6px;
  }
  .result {
    font-size: 1.25rem;
    font-weight: 600;
    color: #2563eb;
  }
</style>
