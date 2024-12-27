import { random } from './math';

export function generateSineWave(width: number, height: number, frequency: number = 1, phase: number = 0): string {
  const points = 100;
  const dx = width / points;
  const path = Array.from({ length: points + 1 }, (_, i) => {
    const x = i * dx;
    const y = height / 2 + Math.sin((x / width) * Math.PI * 2 * frequency + phase) * (height / 3);
    return `${i === 0 ? 'M' : 'L'} ${x} ${y}`;
  }).join(' ');

  return path;
}

export function generateRandomSineWave(): string {
  const width = 100;
  const height = 20;
  const frequency = random(1, 2);
  const phase = random(0, Math.PI * 2);
  
  return generateSineWave(width, height, frequency, phase);
}