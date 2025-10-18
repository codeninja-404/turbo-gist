#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logo
echo -e "${BLUE}"
cat << "EOF"
  ____  __  __  ____    _____                          _ 
 / ___||  \/  |/ ___|  |_   _|_ _ _ __ _ __ ___  _   _| |
 \___ \| |\/| | |        | |/ _` | '__| '_ ` _ \| | | | |
  ___) | |  | | |___     | | (_| | |  | | | | | | |_| |_|
 |____/|_|  |_|\____|    |_|\__,_|_|  |_| |_| |_|\__,_(_)
EOF
echo -e "${NC}"

echo -e "${YELLOW}🚀 Installing sms-turbo monorepo...${NC}"

# Check for required commands
command -v node >/dev/null 2>&1 || { echo -e "${RED}❌ Node.js is required but not installed. Please install Node.js 20+ first.${NC}"; exit 1; }
command -v pnpm >/dev/null 2>&1 || { echo -e "${RED}❌ pnpm is required but not installed. Please install pnpm first: npm install -g pnpm${NC}"; exit 1; }

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2)
REQUIRED_VERSION="20.0.0"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$NODE_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then 
    echo -e "${RED}❌ Node.js version must be 20.0.0 or higher. Current: $NODE_VERSION${NC}"
    exit 1
fi

# Create project directory
PROJECT_NAME="${1:-sms-turbo}"
echo -e "${BLUE}📁 Creating project: $PROJECT_NAME${NC}"

if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}⚠️  Directory $PROJECT_NAME already exists.${NC}"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${NC}"
        exit 1
    fi
    rm -rf "$PROJECT_NAME"
fi

mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Download and extract the project structure
echo -e "${BLUE}📥 Creating project structure...${NC}"

# Create basic directory structure
create_directories() {
    echo -e "${YELLOW}📁 Creating directory structure...${NC}"
    
    mkdir -p apps/client-template/{public,src} 
    mkdir -p packages/{config,router,theme,ui,utils,store,components}/src
    mkdir -p packages/store/src/{api,slices}
    mkdir -p packages/components/src/{pages,layout}
    mkdir -p scripts mock-server
    
    echo -e "${GREEN}✅ Directory structure created${NC}"
}

# Create root configuration files
create_root_files() {
    echo -e "${YELLOW}📄 Creating root configuration files...${NC}"
    
    # package.json
    cat > package.json << 'EOF'
{
  "name": "sms-turbo",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev",
    "lint": "turbo run lint",
    "test": "turbo run test",
    "create-client": "./scripts/create-client.sh",
    "install:clean": "rm -rf node_modules && pnpm install",
    "mock-api": "node mock-server/theme-api.js"
  },
  "devDependencies": {
    "@types/node": "^22.7.4",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "tailwindcss": "^3.4.17",
    "typescript": "~5.6.2",
    "turbo": "^2.5.8",
    "@reduxjs/toolkit": "^2.2.7",
    "react-redux": "^9.1.2",
    "react-router-dom": "^6.30.0"
  },
  "packageManager": "pnpm@9.12.2",
  "engines": {
    "node": ">=20.0.0"
  }
}
EOF

    # pnpm-workspace.yaml
    cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF

    # tsconfig.json
    cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "jsx": "react-jsx",
    "moduleResolution": "node",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "skipLibCheck": true,
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@repo/*": ["packages/*/src"]
    }
  },
  "include": [
    "apps/**/*",
    "packages/**/*"
  ],
  "exclude": ["node_modules", "dist"]
}
EOF

    # turbo.json
    cat > turbo.json << 'EOF'
{
  "$schema": "https://turbo.build/schema.json",
  "tasks": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "lint": {},
    "test": {}
  }
}
EOF

    # .gitignore
    cat > .gitignore << 'EOF'
# See https://help.github.com/articles/ignoring-files/ for more about ignoring files.

# dependencies
/node_modules
/.pnpm-store
/.pnp
.pnp.js
.yarn/install-state.gz

# testing
/coverage

# next.js
/.next/
/out/

# production
/build
/dist

# misc
.DS_Store
*.pem

# debug
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# local env files
.env*.local

# vercel
.vercel

# typescript
*.tsbuildinfo
next-env.d.ts

# mock server
mock-server/node_modules
EOF

    echo -e "${GREEN}✅ Root configuration files created${NC}"
}

# Create shared packages
create_shared_packages() {
    echo -e "${YELLOW}📦 Creating shared packages...${NC}"
    
    # packages/config
    cat > packages/config/package.json << 'EOF'
{
  "name": "@repo/config",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts"
}
EOF

    cat > packages/config/src/index.ts << 'EOF'
// Shared env and global config
export const getEnv = (key: string, fallback?: string): string => {
  return import.meta.env[key] || fallback || '';
};

export const isDev = () => import.meta.env.DEV;

// Theme configuration
export const getPrimaryColor = (): string => {
  return getEnv('VITE_PRIMARY_COLOR', '#1677ff');
};

export const getThemeConfig = () => ({
  primaryColor: getPrimaryColor(),
  clientName: getEnv('VITE_CLIENT_NAME', 'Template'),
  apiUrl: getEnv('VITE_API_URL', 'http://localhost:3001'),
  clientId: getEnv('VITE_CLIENT_ID', 'default')
});
EOF

    # packages/router
    cat > packages/router/package.json << 'EOF'
{
  "name": "@repo/router",
  "version": "1.0.0",
  "main": "src/index.tsx",
  "types": "src/index.tsx",
  "dependencies": {
    "react": "^18.3.1",
    "react-router-dom": "^6.30.0"
  }
}
EOF

    cat > packages/router/src/index.tsx << 'EOF'
import { createBrowserRouter, RouterProvider, Outlet } from "react-router-dom";
import React from "react";

export const createAppRouter = (routes: any[]) => createBrowserRouter(routes);

interface AppRouterProps {
  routes: any[];
}

export const AppRouter: React.FC<AppRouterProps> = ({ routes }) => (
  <RouterProvider router={createAppRouter(routes)} />
);

export { Outlet };
EOF

    # packages/theme
    cat > packages/theme/package.json << 'EOF'
{
  "name": "@repo/theme",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "devDependencies": {
    "tailwindcss": "^3.4.17",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.1"
  }
}
EOF

    cat > packages/theme/src/index.ts << 'EOF'
import type { Config } from "tailwindcss";

export const themeConfig: Config = {
  darkMode: "class",
  content: [
    "../../apps/**/*.{js,ts,jsx,tsx}",
    "../../packages/**/*.{js,ts,jsx,tsx}"
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1677ff',
          hover: '#0958d9'
        }
      }
    }
  },
  plugins: []
};

export const getRuntimeColorStyles = (primaryColor: string) => `
  .bg-primary { background-color: ${primaryColor}; }
  .text-primary { color: ${primaryColor}; }
  .border-primary { border-color: ${primaryColor}; }
`;
EOF

    # packages/ui
    cat > packages/ui/package.json << 'EOF'
{
  "name": "@repo/ui",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "dependencies": {
    "react": "^18.3.1",
    "antd": "^5.20.0"
  }
}
EOF

    cat > packages/ui/src/index.ts << 'EOF'
export * from "antd";
export { Button, Card, Space, Typography, Layout, ConfigProvider, theme, Menu, Spin, Table, Tag, Input, Row, Col, Statistic, Progress } from "antd";
import type { ThemeConfig } from "antd";

export const createAntdTheme = (primaryColor: string = '#1677ff'): ThemeConfig => {
  return {
    token: {
      colorPrimary: primaryColor,
      borderRadius: 6,
    },
    components: {
      Button: {
        colorPrimary: primaryColor,
        algorithm: true,
      },
      Menu: {
        colorPrimary: primaryColor,
        itemSelectedBg: `${primaryColor}15`,
      },
    },
  };
};

export const defaultAntdTheme = createAntdTheme();
EOF

    # packages/utils
    cat > packages/utils/package.json << 'EOF'
{
  "name": "@repo/utils",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "dependencies": {
    "react": "^18.3.1"
  }
}
EOF

    cat > packages/utils/src/index.ts << 'EOF'
export const hexToRgba = (hex: string, alpha = 1): string => {
  const cleanHex = hex.replace('#', '');
  const r = parseInt(cleanHex.slice(0, 2), 16);
  const g = parseInt(cleanHex.slice(2, 4), 16);
  const b = parseInt(cleanHex.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

export const formatDate = (date: Date | string): string => {
  return new Date(date).toLocaleDateString();
};

export const darkenColor = (hex: string, percent: number): string => {
  const num = parseInt(hex.replace("#", ""), 16);
  const amt = Math.round(2.55 * percent);
  const R = (num >> 16) - amt;
  const G = (num >> 8 & 0x00FF) - amt;
  const B = (num & 0x0000FF) - amt;
  return "#" + (
    0x1000000 +
    (R < 255 ? R < 1 ? 0 : R : 255) * 0x10000 +
    (G < 255 ? G < 1 ? 0 : G : 255) * 0x100 +
    (B < 255 ? B < 1 ? 0 : B : 255)
  ).toString(16).slice(1);
};

export const lightenColor = (hex: string, percent: number): string => {
  const num = parseInt(hex.replace("#", ""), 16);
  const amt = Math.round(2.55 * percent);
  const R = (num >> 16) + amt;
  const G = (num >> 8 & 0x00FF) + amt;
  const B = (num & 0x0000FF) + amt;
  return "#" + (
    0x1000000 +
    (R > 255 ? 255 : R) * 0x10000 +
    (G > 255 ? 255 : G) * 0x100 +
    (B > 255 ? 255 : B)
  ).toString(16).slice(1);
};
EOF

    echo -e "${GREEN}✅ Shared packages created${NC}"
}

# Create store package
create_store_package() {
    echo -e "${YELLOW}🛍️ Creating store package...${NC}"
    
    # packages/store
    cat > packages/store/package.json << 'EOF'
{
  "name": "@repo/store",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "dependencies": {
    "@reduxjs/toolkit": "^2.2.7",
    "react-redux": "^9.1.2",
    "@repo/config": "workspace:*"
  }
}
EOF

    cat > packages/store/src/index.ts << 'EOF'
export { store } from './store';
export type { RootState, AppDispatch } from './store';
export { useAppSelector, useAppDispatch } from './hooks';
export { useGetThemeConfigQuery } from './api/themeApi';
EOF

    cat > packages/store/src/store.ts << 'EOF'
import { configureStore } from '@reduxjs/toolkit';
import { themeApi } from './api/themeApi';
import themeReducer from './slices/themeSlice';

export const store = configureStore({
  reducer: {
    theme: themeReducer,
    [themeApi.reducerPath]: themeApi.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware().concat(themeApi.middleware),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
EOF

    cat > packages/store/src/hooks.ts << 'EOF'
import { useDispatch, useSelector, type TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
EOF

    cat > packages/store/src/slices/themeSlice.ts << 'EOF'
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface ThemeState {
  primaryColor: string;
  clientName: string;
  isLoading: boolean;
}

const initialState: ThemeState = {
  primaryColor: '#1677ff',
  clientName: 'Template',
  isLoading: false,
};

const themeSlice = createSlice({
  name: 'theme',
  initialState,
  reducers: {
    setPrimaryColor: (state, action: PayloadAction<string>) => {
      state.primaryColor = action.payload;
    },
    setClientName: (state, action: PayloadAction<string>) => {
      state.clientName = action.payload;
    },
    setThemeConfig: (state, action: PayloadAction<{ primaryColor: string; clientName: string }>) => {
      state.primaryColor = action.payload.primaryColor;
      state.clientName = action.payload.clientName;
    },
  },
});

export const { setPrimaryColor, setClientName, setThemeConfig } = themeSlice.actions;
export default themeSlice.reducer;
EOF

    cat > packages/store/src/api/themeApi.ts << 'EOF'
import { createApi, fetchBaseQuery } from '@reduxjs/toolkit/query/react';
import { getEnv } from '@repo/config';

export interface ThemeConfigResponse {
  primaryColor: string;
  clientName: string;
  logoUrl?: string;
  features: string[];
}

const API_BASE = getEnv('VITE_API_URL', 'http://localhost:3001');

export const themeApi = createApi({
  reducerPath: 'themeApi',
  baseQuery: fetchBaseQuery({
    baseUrl: `${API_BASE}/api/theme`,
    prepareHeaders: (headers) => {
      headers.set('Content-Type', 'application/json');
      return headers;
    },
  }),
  tagTypes: ['Theme'],
  endpoints: (builder) => ({
    getThemeConfig: builder.query<ThemeConfigResponse, string>({
      query: (clientId) => `/${clientId}`,
      providesTags: ['Theme'],
      transformResponse: (response: any) => ({
        primaryColor: response.primary_color || response.primaryColor || '#1677ff',
        clientName: response.client_name || response.clientName || 'Client',
        logoUrl: response.logo_url || response.logoUrl,
        features: response.features || [],
      }),
    }),
  }),
});

export const { useGetThemeConfigQuery } = themeApi;
EOF

    echo -e "${GREEN}✅ Store package created${NC}"
}

# Create components package (simplified)
create_components_package() {
    echo -e "${YELLOW}🧩 Creating components package...${NC}"
    
    cat > packages/components/package.json << 'EOF'
{
  "name": "@repo/components",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "dependencies": {
    "react": "^18.3.1",
    "@repo/ui": "workspace:*",
    "@repo/store": "workspace:*",
    "@repo/config": "workspace:*",
    "@repo/utils": "workspace:*",
    "react-router-dom": "^6.30.0"
  }
}
EOF

    cat > packages/components/src/index.ts << 'EOF'
export { Header } from './Header';
export { Footer } from './Footer';
export { MainLayout } from './MainLayout';
export { Dashboard } from './pages/Dashboard';
export { Campaigns } from './pages/Campaigns';
EOF

    # Create basic components
    cat > packages/components/src/Header.tsx << 'EOF'
import React from 'react';
import { Layout, Typography, Space, Button } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useNavigate, useLocation } from 'react-router-dom';

const { Header: AntHeader } = Layout;
const { Title } = Typography;

export const Header: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig, isLoading } = useGetThemeConfigQuery(clientId);
  const navigate = useNavigate();
  const location = useLocation();

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const clientName = themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template');

  const handleMenuClick = (key: string) => {
    navigate(`/${key}`);
  };

  return (
    <AntHeader 
      style={{ 
        backgroundColor: primaryColor,
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)'
      }}
    >
      <Space>
        <Title level={3} style={{ color: 'white', margin: 0, fontSize: '20px' }}>
          {clientName}
        </Title>
        {isLoading && (
          <div style={{ color: 'white', fontSize: '12px' }}>Loading...</div>
        )}
      </Space>
      
      <Space>
        <Button 
          type="text" 
          style={{ color: 'white' }}
          onClick={() => handleMenuClick('dashboard')}
        >
          Dashboard
        </Button>
        <Button 
          type="text" 
          style={{ color: 'white' }}
          onClick={() => handleMenuClick('campaigns')}
        >
          Campaigns
        </Button>
      </Space>
    </AntHeader>
  );
};
EOF

    cat > packages/components/src/Footer.tsx << 'EOF'
import React from 'react';
import { Layout, Typography } from '@repo/ui';

const { Footer: AntFooter } = Layout;
const { Text } = Typography;

export const Footer: React.FC = () => {
  return (
    <AntFooter style={{ 
      textAlign: 'center', 
      padding: '16px 24px',
      backgroundColor: '#f0f2f5',
      borderTop: '1px solid #d9d9d9'
    }}>
      <Text type="secondary">
        © 2024 SMS Turbo. Built with React, Ant Design, and Tailwind CSS.
      </Text>
    </AntFooter>
  );
};
EOF

    cat > packages/components/src/MainLayout.tsx << 'EOF'
import React from 'react';
import { Layout } from '@repo/ui';
import { Header } from './Header';
import { Footer } from './Footer';

const { Content } = Layout;

interface MainLayoutProps {
  children: React.ReactNode;
}

export const MainLayout: React.FC<MainLayoutProps> = ({ children }) => {
  return (
    <Layout style={{ minHeight: '100vh' }}>
      <Header />
      <Content style={{ 
        flex: 1,
        padding: '24px',
        backgroundColor: '#f5f5f5'
      }}>
        {children}
      </Content>
      <Footer />
    </Layout>
  );
};
EOF

    # Create pages directory and basic pages
    cat > packages/components/src/pages/Dashboard.tsx << 'EOF'
import React from 'react';
import { Card, Row, Col, Statistic, Button, Typography, Space, Progress } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';

const { Title, Paragraph } = Typography;

export const Dashboard: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');

  return (
    <div>
      <Title level={2}>Dashboard</Title>
      <Paragraph>
        Welcome to your SMS marketing dashboard.
      </Paragraph>

      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic title="Total Campaigns" value={12} valueStyle={{ color: primaryColor }} />
          </Card>
        </Col>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic title="Messages Sent" value={4587} valueStyle={{ color: primaryColor }} />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card title="Quick Actions">
            <Space direction="vertical" style={{ width: '100%' }}>
              <Button 
                type="primary" 
                block 
                style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
              >
                Create New Campaign
              </Button>
              <Button block>Manage Subscribers</Button>
            </Space>
          </Card>
        </Col>
      </Row>
    </div>
  );
};
EOF

    cat > packages/components/src/pages/Campaigns.tsx << 'EOF'
import React from 'react';
import { Card, Button, Typography } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';

const { Title, Paragraph } = Typography;

export const Campaigns: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <Title level={2}>Campaigns</Title>
          <Paragraph>
            Manage your SMS campaigns and track their performance.
          </Paragraph>
        </div>
        <Button 
          type="primary" 
          style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
        >
          Create Campaign
        </Button>
      </div>

      <Card>
        <p>Campaign management interface coming soon...</p>
      </Card>
    </div>
  );
};
EOF

    echo -e "${GREEN}✅ Components package created${NC}"
}

# Create client template
create_client_template() {
    echo -e "${YELLOW}📱 Creating client template...${NC}"
    
    # Client template package.json
    cat > apps/client-template/package.json << 'EOF'
{
  "name": "client-template",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.30.0",
    "@reduxjs/toolkit": "^2.2.7",
    "react-redux": "^9.1.2",
    "react-router-dom": "^6.30.0",
    "@repo/ui": "workspace:*",
    "@repo/router": "workspace:*",
    "@repo/theme": "workspace:*",
    "@repo/utils": "workspace:*",
    "@repo/config": "workspace:*",
    "@repo/store": "workspace:*",
    "@repo/components": "workspace:*"
  },
  "devDependencies": {
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "@vitejs/plugin-react": "^4.3.3",
    "eslint": "^9.12.0",
    "eslint-plugin-react-hooks": "^5.1.0-rc.0",
    "eslint-plugin-react-refresh": "^0.4.15",
    "tailwindcss": "^3.4.17",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.1",
    "typescript": "~5.6.2",
    "vite": "^5.4.9"
  }
}
EOF

    # Client template config files
    cat > apps/client-template/tsconfig.json << 'EOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "jsx": "react-jsx"
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
EOF

    cat > apps/client-template/tsconfig.node.json << 'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "composite": true,
    "skipLibCheck": true,
    "module": "ESNext",
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
EOF

    cat > apps/client-template/vite.config.ts << 'EOF'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      "@repo": path.resolve(__dirname, "../../packages")
    }
  },
  server: {
    port: 5173,
    strictPort: true
  }
})
EOF

    cat > apps/client-template/tailwind.config.ts << 'EOF'
import { themeConfig } from "@repo/theme";
export default themeConfig;
EOF

    cat > apps/client-template/postcss.config.js << 'EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
EOF

    cat > apps/client-template/index.html << 'EOF'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/vite.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>SMS Turbo - Client Template</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
EOF

    # Environment files
    cat > apps/client-template/.env.example << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=default
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=Template Client
EOF

    cat > apps/client-template/.env << 'EOF'
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=default
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=Template Client
EOF

    # Client template source files
    cat > apps/client-template/src/main.tsx << 'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import { Provider } from 'react-redux'
import { store } from '@repo/store'
import App from './App.tsx'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <Provider store={store}>
      <App />
    </Provider>
  </React.StrictMode>,
)
EOF

    cat > apps/client-template/src/index.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

body {
  margin: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue',
    sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}
EOF

    # Main App file
    cat > apps/client-template/src/App.tsx << 'EOF'
import React from 'react'
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom'
import { ConfigProvider, Spin } from "@repo/ui";
import { useGetThemeConfigQuery } from "@repo/store";
import { getEnv } from "@repo/config";
import { createAntdTheme } from "@repo/ui";
import { MainLayout, Dashboard, Campaigns } from "@repo/components";
import "./App.css";

const AppContent = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig, isLoading } = useGetThemeConfigQuery(clientId);

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const antdTheme = createAntdTheme(primaryColor);

  if (isLoading) {
    return (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh' 
      }}>
        <Spin size="large" />
      </div>
    );
  }

  const router = createBrowserRouter([
    {
      path: "/",
      element: (
        <ConfigProvider theme={antdTheme}>
          <MainLayout>
            <Navigate to="/dashboard" replace />
          </MainLayout>
        </ConfigProvider>
      ),
    },
    {
      path: "/dashboard",
      element: (
        <ConfigProvider theme={antdTheme}>
          <MainLayout>
            <Dashboard />
          </MainLayout>
        </ConfigProvider>
      ),
    },
    {
      path: "/campaigns",
      element: (
        <ConfigProvider theme={antdTheme}>
          <MainLayout>
            <Campaigns />
          </MainLayout>
        </ConfigProvider>
      ),
    },
  ]);

  return <RouterProvider router={router} />;
};

export default function App() {
  return <AppContent />;
}
EOF

    cat > apps/client-template/src/App.css << 'EOF'
#root {
  width: 100%;
}

.ant-layout-header {
  line-height: 1.6 !important;
}

.ant-card {
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  border: 1px solid #e8e8e8;
}
EOF

    cat > apps/client-template/src/vite-env.d.ts << 'EOF'
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  readonly VITE_CLIENT_NAME: string
  readonly VITE_PRIMARY_COLOR: string
  readonly VITE_CLIENT_ID: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
EOF

    # Create public assets
    mkdir -p apps/client-template/public
    cat > apps/client-template/public/vite.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="iconify iconify--logos" width="31.88" height="32" preserveAspectRatio="xMidYMid meet" viewBox="0 0 256 257"><defs><linearGradient id="IconifyId1813088fe1fbc01fb466" x1="-.828%" x2="57.636%" y1="7.652%" y2="78.411%"><stop offset="0%" stop-color="#41D1FF"></stop><stop offset="100%" stop-color="#BD34FE"></stop></linearGradient><linearGradient id="IconifyId1813088fe1fbc01fb467" x1="43.376%" x2="50.316%" y1="2.242%" y2="89.03%"><stop offset="0%" stop-color="#FFEA83"></stop><stop offset="8.333%"