export type AnimationType = 'none' | 'fade' | 'ink_reveal' | 'brush_stroke' | 'chroma_key';
export type TextAlign = 'left' | 'center' | 'right';
export type ImageFit = 'cover' | 'contain';
export type Orientation = '16:9' | '9:16';

export interface TextElementConfig {
  id: string;
  field: string;
  label: string;
  defaultText: string;
  x: number;
  y: number;
  fontSize: number;
  fontFamily: string;
  fontColor: string;
  textAlign: TextAlign;
  startTime: number;
  endTime: number;
  fadeIn: number;
  fadeOut: number;
  rotation?: number;
}

export interface ImageElementConfig {
  id: string;
  field: string;
  label: string;
  x: number;
  y: number;
  width: number;
  height: number;
  fit: ImageFit;
  startTime: number;
  endTime: number;
  animationType: AnimationType;
  animationDuration: number;
  placeholderUrl?: string;
  rotation?: number;
  chromaKey?: boolean;
  chromaKeyColor?: string;
  chromaKeySimilarity?: number;
  chromaKeyBlend?: number;
}

export interface InvitationTemplate {
  id: string;
  title: string;
  category: string;
  religion: string;
  orientation: Orientation;
  canvasWidth: number;
  canvasHeight: number;
  hasPhoto: boolean;
  photoSlotsCount: number;
  durationSeconds: number;
  badgeText: string;
  description: string;
  masterVideoPath: string;
  videoUrl: string;
  thumbnailUrl: string;
  templateThumbUrl?: string;
  sampleResultPath?: string;
  textElements: TextElementConfig[];
  imageElements: ImageElementConfig[];
  isPublished?: boolean;
  is_published?: boolean;
  status?: string;
  currentVersion?: number;
  tags?: string[];
  isPopular?: boolean;
  isNew?: boolean;
  is_popular?: boolean;
  is_new?: boolean;
  audioPath?: string;
  audioUrl?: string;
  createdAt?: string;
  updatedAt?: string;
}

export interface MediaAsset {
  name: string;
  filePath: string;
  url: string;
  type: 'video' | 'image';
  sizeBytes: number;
}

