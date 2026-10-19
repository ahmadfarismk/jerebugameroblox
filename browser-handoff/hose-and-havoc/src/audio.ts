let context: AudioContext | undefined;
export function tone(muted: boolean) {
  if (muted) return;
  try {
    context ??= new AudioContext();
    void context.resume();
    const o = context.createOscillator(),
      g = context.createGain();
    o.connect(g);
    g.connect(context.destination);
    o.type = "sine";
    o.frequency.setValueAtTime(520, context.currentTime);
    o.frequency.exponentialRampToValueAtTime(260, context.currentTime + 0.15);
    g.gain.setValueAtTime(0.05, context.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, context.currentTime + 0.2);
    o.start();
    o.stop(context.currentTime + 0.2);
  } catch {
    /* silent fallback */
  }
}
