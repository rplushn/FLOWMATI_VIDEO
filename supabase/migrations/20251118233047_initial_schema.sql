-- Users table (extends Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'weekly', 'monthly', 'pro')),
  stripe_customer_id TEXT,
  stripe_subscription_id TEXT,
  subscription_status TEXT DEFAULT 'inactive' CHECK (subscription_status IN ('active', 'inactive', 'cancelled', 'past_due')),
  credits_remaining INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Video Templates table
CREATE TABLE public.templates (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('pov', 'reddit_comments', 'twitter_comments', 'ugc', 'gaming', 'text_to_video', 'image_to_video')),
  description TEXT,
  config JSONB DEFAULT '{}',
  thumbnail_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Videos table
CREATE TABLE public.videos (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  template_id UUID REFERENCES public.templates(id),
  title TEXT,
  template_type TEXT NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed')),
  video_url TEXT,
  thumbnail_url TEXT,
  duration INTEGER,
  config JSONB DEFAULT '{}',
  metadata JSONB DEFAULT '{}',
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User Media library
CREATE TABLE public.media (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('image', 'voice', 'music', 'video')),
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  file_size INTEGER,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Usage tracking
CREATE TABLE public.usage_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  credits_used INTEGER DEFAULT 1,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_videos_user_id ON public.videos(user_id);
CREATE INDEX idx_videos_status ON public.videos(status);
CREATE INDEX idx_videos_created_at ON public.videos(created_at DESC);
CREATE INDEX idx_media_user_id ON public.media(user_id);
CREATE INDEX idx_media_type ON public.media(type);
CREATE INDEX idx_usage_logs_user_id ON public.usage_logs(user_id);

-- RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.videos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view own videos" ON public.videos FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create videos" ON public.videos FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own videos" ON public.videos FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own videos" ON public.videos FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own media" ON public.media FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create media" ON public.media FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own media" ON public.media FOR DELETE USING (auth.uid() = user_id);
CREATE POLICY "Users can view own usage logs" ON public.usage_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Anyone can view templates" ON public.templates FOR SELECT USING (is_active = true);

-- Function for new user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, avatar_url)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'avatar_url');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Default templates
INSERT INTO public.templates (name, type, description) VALUES
  ('POV Videos', 'pov', 'Create viral POV style videos'),
  ('Reddit Comments', 'reddit_comments', 'Generate videos from Reddit threads'),
  ('Twitter/X Posts', 'twitter_comments', 'Create videos from X/Twitter posts'),
  ('UGC Style', 'ugc', 'User-generated content style videos'),
  ('Gaming Clips', 'gaming', 'Gaming footage with voiceover'),
  ('Text to Video', 'text_to_video', 'Generate video from text prompt'),
  ('Image to Video', 'image_to_video', 'Animate your images into videos');
