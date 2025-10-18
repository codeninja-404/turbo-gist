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
cat << "LOGOEOF"
  ____  __  __  ____    _____                          _ 
 / ___||  \/  |/ ___|  |_   _|_ _ _ __ _ __ ___  _   _| |
 \___ \| |\/| | |        | |/ _` | '__| '_ ` _ \| | | | |
  ___) | |  | | |___     | | (_| | |  | | | | | | |_| |_|
 |____/|_|  |_|\____|    |_|\__,_|_|  |_| |_| |_|\__,_(_)
LOGOEOF
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
    echo -e "${YELLOW}⚠️  Directory $PROJECT_NAME already exists. Using existing directory.${NC}"
else
    mkdir -p "$PROJECT_NAME"
fi

cd "$PROJECT_NAME"

# Download and extract the project structure
echo -e "${BLUE}📥 Creating project structure...${NC}"

# Create the complete project structure
create_project_structure() {
    # Create root structure
    mkdir -p apps/client-template/{public,src/{components,pages,utils,types}} 
    mkdir -p packages/{config,router,theme,ui,utils,store,components}/src
    mkdir -p packages/store/src/{api,slices}
    mkdir -p packages/components/src/{pages,layout,ui}
    mkdir -p scripts mock-server

    # Create root package.json with ALL dependencies
    cat > package.json << 'ROOTPKGEOF'
{
  "name": "sms-turbo",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "build": "turbo run build",
    "dev": "turbo run dev --parallel",
    "lint": "turbo run lint",
    "test": "turbo run test",
    "create-client": "./scripts/create-client.sh",
    "install:clean": "rm -rf node_modules && pnpm install",
    "mock-api": "node mock-server/theme-api.js"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.30.0",
    "@reduxjs/toolkit": "^2.2.7",
    "react-redux": "^9.1.2",
    "antd": "^5.20.0"
  },
  "devDependencies": {
    "@types/node": "^22.7.4",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "tailwindcss": "^3.4.17",
    "typescript": "~5.6.2",
    "turbo": "^2.5.8",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.5.1",
    "@vitejs/plugin-react": "^4.3.3",
    "eslint": "^9.12.0",
    "eslint-plugin-react-hooks": "^5.1.0-rc.0",
    "eslint-plugin-react-refresh": "^0.4.15",
    "vite": "^5.4.9"
  },
  "packageManager": "pnpm@9.12.2",
  "engines": {
    "node": ">=20.0.0"
  }
}
ROOTPKGEOF

    cat > pnpm-workspace.yaml << 'WORKSPACEEOF'
packages:
  - "apps/*"
  - "packages/*"
WORKSPACEEOF

    cat > tsconfig.json << 'TSCONFIGEOF'
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "lib": ["ESNext", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "skipLibCheck": true,
    "strict": true,
    "baseUrl": ".",
    "paths": {
      "@repo/*": ["./packages/*/src"],
      "@/*": ["./apps/*/src"]
    },
    "types": ["vite/client"]
  },
  "include": [
    "apps/**/*",
    "packages/**/*",
    "**/*.ts",
    "**/*.tsx"
  ],
  "exclude": ["node_modules", "dist"]
}
TSCONFIGEOF

    cat > turbo.json << 'TURBOEOF'
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
TURBOEOF

    cat > .gitignore << 'GITIGNOREEOF'
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

# IDE
.vscode
.idea
*.swp
*.swo

# OS
Thumbs.db
GITIGNOREEOF

    # Create shared packages (NO dependencies - they come from root)
    create_shared_packages
    # Create client template (NO dependencies - they come from root)
    create_client_template
    # Create scripts
    create_scripts
    # Create mock server
    create_mock_server
}

create_shared_packages() {
    # packages/config - NO dependencies
    cat > packages/config/package.json << 'PKGCONFIGEOF'
{
  "name": "@repo/config",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for config package'"
  }
}
PKGCONFIGEOF

    cat > packages/config/src/index.ts << 'CONFIGEOF'
// Shared env and global config
export const getEnv = (key: string, fallback?: string): string => {
  // For Vite environment variables
  if (typeof import.meta !== 'undefined' && import.meta.env) {
    return import.meta.env[key] || fallback || '';
  }
  // For Node.js environment
  if (typeof process !== 'undefined' && process.env) {
    return process.env[key] || fallback || '';
  }
  return fallback || '';
};

export const isDev = (): boolean => {
  return getEnv('NODE_ENV') === 'development' || getEnv('DEV') === 'true' || getEnv('VITE_DEV') === 'true';
};

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
CONFIGEOF

    # packages/router - NO dependencies (they're in root)
    cat > packages/router/package.json << 'PKGROUTEREOF'
{
  "name": "@repo/router",
  "version": "1.0.0",
  "main": "src/index.tsx",
  "types": "src/index.tsx",
  "scripts": {
    "dev": "echo 'No dev script for router package'"
  }
}
PKGROUTEREOF

    cat > packages/router/src/index.tsx << 'ROUTEREOF'
import { createBrowserRouter, RouterProvider, Outlet, Navigate } from "react-router-dom";
import React from "react";

export const createAppRouter = (routes: any[]) => createBrowserRouter(routes);

interface AppRouterProps {
  routes: any[];
}

export const AppRouter: React.FC<AppRouterProps> = ({ routes }) => (
  <RouterProvider router={createAppRouter(routes)} />
);

export { Outlet, Navigate };
export { useNavigate, useLocation, useParams } from 'react-router-dom';
ROUTEREOF

    # packages/theme - NO dependencies
    cat > packages/theme/package.json << 'PKGTHEMEEOF'
{
  "name": "@repo/theme",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for theme package'"
  }
}
PKGTHEMEEOF

    cat > packages/theme/src/index.ts << 'THEMEEOF'
import type { Config } from "tailwindcss";

export const themeConfig: Config = {
  darkMode: "class",
  content: [
    "./src/**/*.{js,ts,jsx,tsx}",
    "../../apps/**/src/**/*.{js,ts,jsx,tsx}",
    "../../packages/ui/src/**/*.{js,ts,jsx,tsx}",
    "../../packages/components/src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1677ff',
          50: '#f0f8ff',
          100: '#e0f0ff',
          200: '#bae0ff',
          300: '#91caff',
          400: '#69b1ff',
          500: '#1677ff',
          600: '#0958d9',
          700: '#003eb3',
          800: '#002c8c',
          900: '#001d66',
        }
      },
      animation: {
        'fade-in': 'fadeIn 0.5s ease-in-out',
        'slide-up': 'slideUp 0.3s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      }
    }
  },
  plugins: []
};

export const getRuntimeColorStyles = (primaryColor: string) => `
  .bg-primary { background-color: ${primaryColor}; }
  .text-primary { color: ${primaryColor}; }
  .border-primary { border-color: ${primaryColor}; }
  .hover\\:bg-primary:hover { background-color: ${primaryColor}; }
  .hover\\:text-primary:hover { color: ${primaryColor}; }
`;
THEMEEOF

    # packages/ui - NO dependencies (antd is in root)
    cat > packages/ui/package.json << 'PKGUIEOF'
{
  "name": "@repo/ui",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for ui package'"
  }
}
PKGUIEOF

    cat > packages/ui/src/index.ts << 'UIEOF'
export * from "antd";
export { 
  Button, 
  Card, 
  Space, 
  Typography, 
  Layout, 
  ConfigProvider, 
  theme, 
  Menu, 
  Spin, 
  Table, 
  Tag, 
  Input, 
  Row, 
  Col, 
  Statistic, 
  Progress,
  Form,
  Select,
  Modal,
  message,
  notification,
  Avatar,
  Dropdown,
  Tabs,
  List,
  Tooltip,
  Popconfirm,
  Badge,
  Divider,
  Result,
  Empty
} from "antd";
import type { ThemeConfig } from "antd";

export const createAntdTheme = (primaryColor: string = '#1677ff'): ThemeConfig => {
  return {
    token: {
      colorPrimary: primaryColor,
      borderRadius: 6,
      colorBgContainer: '#ffffff',
      colorText: '#333333',
    },
    components: {
      Button: {
        colorPrimary: primaryColor,
        algorithm: true,
      },
      Menu: {
        colorPrimary: primaryColor,
        itemSelectedBg: \`\${primaryColor}15\`,
        itemHoverBg: \`\${primaryColor}08\`,
      },
      Card: {
        boxShadowTertiary: '0 1px 2px 0 rgba(0, 0, 0, 0.03), 0 1px 6px -1px rgba(0, 0, 0, 0.02), 0 2px 4px 0 rgba(0, 0, 0, 0.02)',
      },
    },
  };
};

export const defaultAntdTheme = createAntdTheme();

// Custom UI components
export const LoadingSpinner = () => (
  <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', padding: '50px' }}>
    <Spin size="large" />
  </div>
);

export const ErrorMessage = ({ message }: { message: string }) => (
  <Result
    status="error"
    title="Error"
    subTitle={message}
    extra={[
      <Button type="primary" key="console" onClick={() => window.location.reload()}>
        Try Again
      </Button>,
    ]}
  />
);
UIEOF

    # packages/utils - NO dependencies
    cat > packages/utils/package.json << 'PKGUTILSEOF'
{
  "name": "@repo/utils",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for utils package'"
  }
}
PKGUTILSEOF

    cat > packages/utils/src/index.ts << 'UTILSEOF'
export const hexToRgba = (hex: string, alpha = 1): string => {
  const cleanHex = hex.replace('#', '');
  const r = parseInt(cleanHex.slice(0, 2), 16);
  const g = parseInt(cleanHex.slice(2, 4), 16);
  const b = parseInt(cleanHex.slice(4, 6), 16);
  return \`rgba(\${r}, \${g}, \${b}, \${alpha})\`;
};

export const formatDate = (date: Date | string): string => {
  return new Date(date).toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  });
};

export const formatDateTime = (date: Date | string): string => {
  return new Date(date).toLocaleString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  });
};

export const darkenColor = (hex: string, percent: number): string => {
  const num = parseInt(hex.replace("#", ""), 16);
  const amt = Math.round(2.55 * percent);
  const R = Math.max(0, (num >> 16) - amt);
  const G = Math.max(0, (num >> 8 & 0x00FF) - amt);
  const B = Math.max(0, (num & 0x0000FF) - amt);
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
  const R = Math.min(255, (num >> 16) + amt);
  const G = Math.min(255, (num >> 8 & 0x00FF) + amt);
  const B = Math.min(255, (num & 0x0000FF) + amt);
  return "#" + (
    0x1000000 +
    (R > 255 ? 255 : R) * 0x10000 +
    (G > 255 ? 255 : G) * 0x100 +
    (B > 255 ? 255 : B)
  ).toString(16).slice(1);
};

export const generateId = (): string => {
  return Math.random().toString(36).substr(2, 9) + Date.now().toString(36);
};

export const debounce = <T extends (...args: any[]) => any>(
  func: T,
  wait: number
): ((...args: Parameters<T>) => void) => {
  let timeout: NodeJS.Timeout;
  return (...args: Parameters<T>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(null, args), wait);
  };
};

export const classNames = (...classes: (string | undefined | null | false)[]): string => {
  return classes.filter(Boolean).join(' ');
};
UTILSEOF

    # packages/store - NO dependencies (they're in root)
    cat > packages/store/package.json << 'PKGSTOREEOF'
{
  "name": "@repo/store",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for store package'"
  }
}
PKGSTOREEOF

    cat > packages/store/src/index.ts << 'STOREEOF'
export { store } from './store';
export type { RootState, AppDispatch } from './store';
export { useAppSelector, useAppDispatch } from './hooks';
export { useGetThemeConfigQuery } from './api/themeApi';
STOREEOF

    cat > packages/store/src/store.ts << 'STORETSEOF'
import { configureStore } from '@reduxjs/toolkit';
import { themeApi } from './api/themeApi';
import themeReducer from './slices/themeSlice';

export const store = configureStore({
  reducer: {
    theme: themeReducer,
    [themeApi.reducerPath]: themeApi.reducer,
  },
  middleware: (getDefaultMiddleware) =>
    getDefaultMiddleware({
      serializableCheck: {
        ignoredActions: ['persist/PERSIST'],
      },
    }).concat(themeApi.middleware),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
STORETSEOF

    cat > packages/store/src/hooks.ts << 'HOOKSEOF'
import { useDispatch, useSelector, type TypedUseSelectorHook } from 'react-redux';
import type { RootState, AppDispatch } from './store';

export const useAppDispatch = () => useDispatch<AppDispatch>();
export const useAppSelector: TypedUseSelectorHook<RootState> = useSelector;
HOOKSEOF

    cat > packages/store/src/slices/themeSlice.ts << 'SLICEEOF'
import { createSlice, PayloadAction } from '@reduxjs/toolkit';

interface ThemeState {
  primaryColor: string;
  clientName: string;
  isLoading: boolean;
  logoUrl?: string;
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
    setThemeConfig: (state, action: PayloadAction<{ primaryColor: string; clientName: string; logoUrl?: string }>) => {
      state.primaryColor = action.payload.primaryColor;
      state.clientName = action.payload.clientName;
      state.logoUrl = action.payload.logoUrl;
    },
    setLoading: (state, action: PayloadAction<boolean>) => {
      state.isLoading = action.payload;
    },
  },
});

export const { setPrimaryColor, setClientName, setThemeConfig, setLoading } = themeSlice.actions;
export default themeSlice.reducer;
SLICEEOF

    cat > packages/store/src/api/themeApi.ts << 'APIEOF'
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
    baseUrl: \`\${API_BASE}/api/theme\`,
    prepareHeaders: (headers) => {
      headers.set('Content-Type', 'application/json');
      return headers;
    },
  }),
  tagTypes: ['Theme'],
  endpoints: (builder) => ({
    getThemeConfig: builder.query<ThemeConfigResponse, string>({
      query: (clientId) => \`/\${clientId}\`,
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
APIEOF

    # packages/components - NO dependencies (they're in root)
    cat > packages/components/package.json << 'PKGCOMPONENTSEOF'
{
  "name": "@repo/components",
  "version": "1.0.0",
  "main": "src/index.ts",
  "types": "src/index.ts",
  "scripts": {
    "dev": "echo 'No dev script for components package'"
  }
}
PKGCOMPONENTSEOF

    cat > packages/components/src/index.ts << 'COMPONENTSEOF'
export { Header } from './layout/Header';
export { Footer } from './layout/Footer';
export { MainLayout } from './layout/MainLayout';
export { Dashboard } from './pages/Dashboard';
export { Campaigns } from './pages/Campaigns';
export { CampaignDetail } from './pages/CampaignDetail';
export { Settings } from './pages/Settings';
export { Profile } from './pages/Profile';
export { LoadingSpinner } from './ui/LoadingSpinner';
export { ErrorBoundary } from './ui/ErrorBoundary';
COMPONENTSEOF

    # Create layout directory
    mkdir -p packages/components/src/layout
    mkdir -p packages/components/src/pages
    mkdir -p packages/components/src/ui

    # Header component
    cat > packages/components/src/layout/Header.tsx << 'HEADEREOF'
import { Layout, Typography, Space, Button, Avatar, Dropdown, MenuProps } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useNavigate, useLocation } from 'react-router-dom';
import { useState } from 'react';

const { Header: AntHeader } = Layout;
const { Title } = Typography;

interface HeaderProps {
  onMenuClick?: (key: string) => void;
  currentPage?: string;
}

export const Header: React.FC<HeaderProps> = ({ onMenuClick, currentPage }) => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig, isLoading } = useGetThemeConfigQuery(clientId);
  const navigate = useNavigate();
  const location = useLocation();
  const [activeMenu, setActiveMenu] = useState('dashboard');

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const clientName = themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template');

  const handleMenuClick = (key: string) => {
    setActiveMenu(key);
    if (onMenuClick) {
      onMenuClick(key);
    } else {
      navigate(\`/\${key}\`);
    }
  };

  const getCurrentPage = () => {
    return currentPage || location.pathname.split('/')[1] || 'dashboard';
  };

  const currentPageKey = getCurrentPage();

  const profileItems: MenuProps['items'] = [
    {
      key: 'profile',
      label: 'Profile',
      onClick: () => navigate('/profile'),
    },
    {
      key: 'settings',
      label: 'Settings',
      onClick: () => navigate('/settings'),
    },
    {
      type: 'divider',
    },
    {
      key: 'logout',
      label: 'Logout',
      onClick: () => console.log('Logout clicked'),
    },
  ];

  return (
    <AntHeader 
      style={{ 
        backgroundColor: primaryColor,
        padding: '0 24px',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
        position: 'sticky',
        top: 0,
        zIndex: 1000,
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
      
      <Space size="middle">
        <Button 
          type="text" 
          style={{ 
            color: 'white',
            fontWeight: currentPageKey === 'dashboard' ? 'bold' : 'normal',
            backgroundColor: currentPageKey === 'dashboard' ? 'rgba(255,255,255,0.2)' : 'transparent'
          }}
          onClick={() => handleMenuClick('dashboard')}
        >
          Dashboard
        </Button>
        <Button 
          type="text" 
          style={{ 
            color: 'white',
            fontWeight: currentPageKey === 'campaigns' ? 'bold' : 'normal',
            backgroundColor: currentPageKey === 'campaigns' ? 'rgba(255,255,255,0.2)' : 'transparent'
          }}
          onClick={() => handleMenuClick('campaigns')}
        >
          Campaigns
        </Button>
        <Button 
          type="text" 
          style={{ 
            color: 'white',
            fontWeight: currentPageKey === 'settings' ? 'bold' : 'normal',
            backgroundColor: currentPageKey === 'settings' ? 'rgba(255,255,255,0.2)' : 'transparent'
          }}
          onClick={() => handleMenuClick('settings')}
        >
          Settings
        </Button>
        
        <Dropdown menu={{ items: profileItems }} placement="bottomRight">
          <Avatar 
            style={{ 
              backgroundColor: 'rgba(255,255,255,0.2)',
              cursor: 'pointer'
            }}
          >
            {clientName.charAt(0).toUpperCase()}
          </Avatar>
        </Dropdown>
      </Space>
    </AntHeader>
  );
};
HEADEREOF

    # Footer component
    cat > packages/components/src/layout/Footer.tsx << 'FOOTEREOF'
import { Layout, Typography, Space } from '@repo/ui';
import { getEnv } from '@repo/config';

const { Footer: AntFooter } = Layout;
const { Text } = Typography;

export const Footer: React.FC = () => {
  const clientName = getEnv('VITE_CLIENT_NAME', 'Template');

  return (
    <AntFooter style={{ 
      textAlign: 'center', 
      padding: '16px 24px',
      backgroundColor: '#f0f2f5',
      borderTop: '1px solid #d9d9d9'
    }}>
      <Space direction="vertical" size="small">
        <Text type="secondary">
          © 2024 {clientName}. Built with React, Ant Design, and Tailwind CSS.
        </Text>
        <Text type="secondary" style={{ fontSize: '12px' }}>
          SMS Turbo Platform - Powerful SMS Marketing Solutions
        </Text>
      </Space>
    </AntFooter>
  );
};
FOOTEREOF

    # MainLayout component
    cat > packages/components/src/layout/MainLayout.tsx << 'LAYOUTEOF'
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
        backgroundColor: '#f5f5f5',
        minHeight: 'calc(100vh - 128px)'
      }}>
        {children}
      </Content>
      <Footer />
    </Layout>
  );
};
LAYOUTEOF

    # LoadingSpinner component
    cat > packages/components/src/ui/LoadingSpinner.tsx << 'SPINNEREOF'
import { Spin, Space, Typography } from '@repo/ui';

const { Text } = Typography;

interface LoadingSpinnerProps {
  size?: 'small' | 'default' | 'large';
  text?: string;
}

export const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  size = 'large', 
  text = 'Loading...' 
}) => {
  return (
    <div style={{ 
      display: 'flex', 
      justifyContent: 'center', 
      alignItems: 'center', 
      height: '200px',
      flexDirection: 'column',
      gap: '16px'
    }}>
      <Spin size={size} />
      {text && <Text type="secondary">{text}</Text>}
    </div>
  );
};
SPINNEREOF

    # ErrorBoundary component
    cat > packages/components/src/ui/ErrorBoundary.tsx << 'ERRORBOUNDARYEOF'
import React from 'react';
import { Result, Button } from '@repo/ui';

interface ErrorBoundaryState {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends React.Component<
  { children: React.ReactNode },
  ErrorBoundaryState
> {
  constructor(props: { children: React.ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <Result
          status="500"
          title="Something went wrong"
          subTitle={this.state.error?.message || 'An unexpected error occurred'}
          extra={
            <Button 
              type="primary" 
              onClick={() => {
                this.setState({ hasError: false, error: undefined });
                window.location.href = '/';
              }}
            >
              Back to Home
            </Button>
          }
        />
      );
    }

    return this.props.children;
  }
}
ERRORBOUNDARYEOF

    # Dashboard page
    cat > packages/components/src/pages/Dashboard.tsx << 'DASHBOARDEOF'
import { Card, Row, Col, Statistic, Button, Typography, Space, Progress, Tabs } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useNavigate } from 'react-router-dom';
import { formatDate } from '@repo/utils';

const { Title, Paragraph } = Typography;
const { TabPane } = Tabs;

export const Dashboard: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const navigate = useNavigate();

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const clientName = themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template');

  const recentCampaigns = [
    { id: '1', name: 'Welcome Series', status: 'active', progress: 85 },
    { id: '2', name: 'Flash Sale', status: 'completed', progress: 100 },
    { id: '3', name: 'Newsletter', status: 'draft', progress: 0 },
  ];

  return (
    <div className="animate-fade-in">
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        <div>
          <Title level={2}>Welcome back, {clientName}!</Title>
          <Paragraph>
            Here's what's happening with your SMS campaigns today.
          </Paragraph>
        </div>

        <Row gutter={[16, 16]}>
          <Col xs={24} sm={12} md={6}>
            <Card>
              <Statistic 
                title="Total Campaigns" 
                value={12} 
                valueStyle={{ color: primaryColor }} 
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Card>
              <Statistic 
                title="Messages Sent" 
                value={4587} 
                valueStyle={{ color: primaryColor }} 
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Card>
              <Statistic 
                title="Delivery Rate" 
                value={98.2} 
                suffix="%" 
                valueStyle={{ color: primaryColor }} 
              />
            </Card>
          </Col>
          <Col xs={24} sm={12} md={6}>
            <Card>
              <Statistic 
                title="Active Subscribers" 
                value={2450} 
                valueStyle={{ color: primaryColor }} 
              />
            </Card>
          </Col>
        </Row>

        <Row gutter={[16, 16]}>
          <Col xs={24} lg={16}>
            <Card title="Recent Campaigns" extra={
              <Button 
                type="link" 
                style={{ color: primaryColor }}
                onClick={() => navigate('/campaigns')}
              >
                View All
              </Button>
            }>
              <Space direction="vertical" style={{ width: '100%' }}>
                {recentCampaigns.map(campaign => (
                  <Card 
                    key={campaign.id}
                    size="small" 
                    style={{ 
                      borderLeft: \`4px solid \${primaryColor}\`,
                      cursor: 'pointer'
                    }}
                    onClick={() => navigate(\`/campaigns/\${campaign.id}\`)}
                  >
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <div>
                        <div style={{ fontWeight: 'bold' }}>{campaign.name}</div>
                        <div style={{ fontSize: '12px', color: '#666' }}>
                          Status: {campaign.status}
                        </div>
                      </div>
                      <Progress 
                        percent={campaign.progress} 
                        size="small" 
                        strokeColor={primaryColor}
                        style={{ width: '100px' }}
                      />
                    </div>
                  </Card>
                ))}
              </Space>
            </Card>
          </Col>
          
          <Col xs={24} lg={8}>
            <Card title="Quick Actions">
              <Space direction="vertical" style={{ width: '100%' }}>
                <Button 
                  type="primary" 
                  block 
                  style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
                  onClick={() => navigate('/campaigns/new')}
                >
                  Create New Campaign
                </Button>
                <Button block onClick={() => navigate('/subscribers')}>
                  Manage Subscribers
                </Button>
                <Button block onClick={() => navigate('/analytics')}>
                  View Analytics
                </Button>
                <Button block onClick={() => navigate('/settings')}>
                  Account Settings
                </Button>
              </Space>
            </Card>

            {themeConfig?.features && themeConfig.features.length > 0 && (
              <Card title="Available Features" style={{ marginTop: 16 }}>
                <Space direction="vertical" style={{ width: '100%' }}>
                  {themeConfig.features.map((feature, index) => (
                    <div 
                      key={index}
                      style={{ 
                        padding: '8px 12px',
                        backgroundColor: \`\${primaryColor}10\`,
                        borderRadius: '4px',
                        borderLeft: \`3px solid \${primaryColor}\`
                      }}
                    >
                      <span style={{ color: primaryColor, marginRight: '8px' }}>✓</span>
                      {feature}
                    </div>
                  ))}
                </Space>
              </Card>
            )}
          </Col>
        </Row>
      </Space>
    </div>
  );
};
DASHBOARDEOF

    # Campaigns page with dynamic routing
    cat > packages/components/src/pages/Campaigns.tsx << 'CAMPAIGNSEOF'
import { Card, Table, Button, Tag, Space, Typography, Input, Row, Col } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useNavigate } from 'react-router-dom';
import { useState } from 'react';

const { Title, Paragraph } = Typography;
const { Search } = Input;

interface Campaign {
  id: string;
  name: string;
  status: 'active' | 'paused' | 'completed' | 'draft';
  recipients: number;
  sent: number;
  startDate: string;
  type: 'promotional' | 'transactional' | 'alert';
}

const mockCampaigns: Campaign[] = [
  {
    id: '1',
    name: 'Welcome Series',
    status: 'active',
    recipients: 1500,
    sent: 1420,
    startDate: '2024-01-15',
    type: 'promotional'
  },
  {
    id: '2',
    name: 'Order Confirmations',
    status: 'active',
    recipients: 3200,
    sent: 3180,
    startDate: '2024-01-10',
    type: 'transactional'
  },
  {
    id: '3',
    name: 'Flash Sale',
    status: 'completed',
    recipients: 800,
    sent: 800,
    startDate: '2024-01-05',
    type: 'promotional'
  },
  {
    id: '4',
    name: 'Newsletter',
    status: 'draft',
    recipients: 0,
    sent: 0,
    startDate: '2024-01-20',
    type: 'promotional'
  },
];

export const Campaigns: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const [searchText, setSearchText] = useState('');
  const navigate = useNavigate();

  const getStatusColor = (status: Campaign['status']) => {
    switch (status) {
      case 'active': return 'green';
      case 'paused': return 'orange';
      case 'completed': return 'blue';
      case 'draft': return 'gray';
      default: return 'default';
    }
  };

  const getTypeColor = (type: Campaign['type']) => {
    switch (type) {
      case 'promotional': return 'purple';
      case 'transactional': return 'cyan';
      case 'alert': return 'red';
      default: return 'default';
    }
  };

  const filteredCampaigns = mockCampaigns.filter(campaign =>
    campaign.name.toLowerCase().includes(searchText.toLowerCase())
  );

  const columns = [
    {
      title: 'Campaign Name',
      dataIndex: 'name',
      key: 'name',
      render: (name: string, record: Campaign) => (
        <Button 
          type="link" 
          style={{ padding: 0, height: 'auto' }}
          onClick={() => navigate(\`/campaigns/\${record.id}\`)}
        >
          {name}
        </Button>
      ),
    },
    {
      title: 'Status',
      dataIndex: 'status',
      key: 'status',
      render: (status: Campaign['status']) => (
        <Tag color={getStatusColor(status)}>
          {status.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: 'Type',
      dataIndex: 'type',
      key: 'type',
      render: (type: Campaign['type']) => (
        <Tag color={getTypeColor(type)}>
          {type.toUpperCase()}
        </Tag>
      ),
    },
    {
      title: 'Recipients',
      dataIndex: 'recipients',
      key: 'recipients',
      render: (recipients: number) => recipients.toLocaleString(),
    },
    {
      title: 'Sent',
      dataIndex: 'sent',
      key: 'sent',
      render: (sent: number) => sent.toLocaleString(),
    },
    {
      title: 'Start Date',
      dataIndex: 'startDate',
      key: 'startDate',
    },
    {
      title: 'Actions',
      key: 'actions',
      render: (_: any, record: Campaign) => (
        <Space>
          <Button 
            type="link" 
            size="small" 
            style={{ color: primaryColor }}
            onClick={() => navigate(\`/campaigns/\${record.id}/edit\`)}
          >
            Edit
          </Button>
          <Button 
            type="link" 
            size="small" 
            onClick={() => navigate(\`/campaigns/\${record.id}\`)}
          >
            View
          </Button>
        </Space>
      ),
    },
  ];

  return (
    <div className="animate-fade-in">
      <Row justify="space-between" align="middle" style={{ marginBottom: 24 }}>
        <Col>
          <Title level={2}>Campaigns</Title>
          <Paragraph>
            Manage your SMS campaigns and track their performance.
          </Paragraph>
        </Col>
        <Col>
          <Button 
            type="primary" 
            style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
            onClick={() => navigate('/campaigns/new')}
          >
            Create Campaign
          </Button>
        </Col>
      </Row>

      <Card>
        <div style={{ marginBottom: 16 }}>
          <Search
            placeholder="Search campaigns..."
            allowClear
            onSearch={setSearchText}
            style={{ width: 300 }}
          />
        </div>
        
        <Table 
          columns={columns} 
          dataSource={filteredCampaigns}
          rowKey="id"
          pagination={{ pageSize: 10 }}
          onRow={(record) => ({
            onClick: () => navigate(\`/campaigns/\${record.id}\`),
            style: { cursor: 'pointer' }
          })}
        />
      </Card>
    </div>
  );
};
CAMPAIGNSEOF

    # CampaignDetail page for dynamic routes
    cat > packages/components/src/pages/CampaignDetail.tsx << 'CAMPAIGNDETAILEOF'
import { Card, Descriptions, Tag, Button, Space, Typography, Row, Col, Statistic, Progress } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useParams, useNavigate } from 'react-router-dom';
import { formatDate } from '@repo/utils';

const { Title, Paragraph } = Typography;

const mockCampaignDetails: { [key: string]: any } = {
  '1': {
    name: 'Welcome Series',
    status: 'active',
    type: 'promotional',
    recipients: 1500,
    sent: 1420,
    delivered: 1390,
    opened: 890,
    clicked: 450,
    startDate: '2024-01-15',
    endDate: '2024-02-15',
    description: 'Welcome series for new subscribers',
    message: 'Welcome to our service! We are excited to have you on board.',
  },
  '2': {
    name: 'Order Confirmations',
    status: 'active',
    type: 'transactional',
    recipients: 3200,
    sent: 3180,
    delivered: 3150,
    opened: 2800,
    clicked: 1500,
    startDate: '2024-01-10',
    endDate: 'Ongoing',
    description: 'Automatic order confirmation messages',
    message: 'Your order #{{order_id}} has been confirmed and will be shipped soon.',
  },
  '3': {
    name: 'Flash Sale',
    status: 'completed',
    type: 'promotional',
    recipients: 800,
    sent: 800,
    delivered: 780,
    opened: 650,
    clicked: 320,
    startDate: '2024-01-05',
    endDate: '2024-01-07',
    description: '24-hour flash sale announcement',
    message: 'FLASH SALE! 50% off everything for 24 hours only. Use code: FLASH50',
  },
  '4': {
    name: 'Newsletter',
    status: 'draft',
    type: 'promotional',
    recipients: 0,
    sent: 0,
    delivered: 0,
    opened: 0,
    clicked: 0,
    startDate: '2024-01-20',
    endDate: 'TBD',
    description: 'Monthly newsletter update',
    message: 'Check out our latest updates and offers in this month newsletter!',
  }
};

export const CampaignDetail: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const navigate = useNavigate();

  const campaign = id ? mockCampaignDetails[id] : null;

  if (!campaign) {
    return (
      <div style={{ textAlign: 'center', padding: '50px' }}>
        <Title level={3}>Campaign not found</Title>
        <Paragraph>The campaign you are looking for does not exist.</Paragraph>
        <Button 
          type="primary" 
          onClick={() => navigate('/campaigns')}
          style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
        >
          Back to Campaigns
        </Button>
      </div>
    );
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'green';
      case 'paused': return 'orange';
      case 'completed': return 'blue';
      case 'draft': return 'gray';
      default: return 'default';
    }
  };

  const getTypeColor = (type: string) => {
    switch (type) {
      case 'promotional': return 'purple';
      case 'transactional': return 'cyan';
      case 'alert': return 'red';
      default: return 'default';
    }
  };

  const deliveryRate = campaign.sent > 0 ? (campaign.delivered / campaign.sent) * 100 : 0;
  const openRate = campaign.delivered > 0 ? (campaign.opened / campaign.delivered) * 100 : 0;
  const clickRate = campaign.opened > 0 ? (campaign.clicked / campaign.opened) * 100 : 0;

  return (
    <div className="animate-fade-in">
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        <div>
          <Button 
            type="text" 
            onClick={() => navigate('/campaigns')}
            style={{ marginBottom: 16, padding: 0 }}
          >
            ← Back to Campaigns
          </Button>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
            <div>
              <Title level={2}>{campaign.name}</Title>
              <Space size="middle">
                <Tag color={getStatusColor(campaign.status)}>{campaign.status.toUpperCase()}</Tag>
                <Tag color={getTypeColor(campaign.type)}>{campaign.type.toUpperCase()}</Tag>
              </Space>
            </div>
            <Space>
              <Button onClick={() => navigate(\`/campaigns/\${id}/edit\`)}>Edit Campaign</Button>
              <Button 
                type="primary" 
                style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
                disabled={campaign.status === 'draft'}
              >
                {campaign.status === 'draft' ? 'Publish' : 'Send Test'}
              </Button>
            </Space>
          </div>
        </div>

        <Row gutter={[16, 16]}>
          <Col xs={24} lg={16}>
            <Card title="Campaign Details">
              <Descriptions column={1} bordered>
                <Descriptions.Item label="Description">
                  {campaign.description}
                </Descriptions.Item>
                <Descriptions.Item label="Message Content">
                  <div style={{ 
                    backgroundColor: '#f5f5f5', 
                    padding: '12px', 
                    borderRadius: '4px',
                    fontFamily: 'monospace'
                  }}>
                    {campaign.message}
                  </div>
                </Descriptions.Item>
                <Descriptions.Item label="Start Date">
                  {formatDate(campaign.startDate)}
                </Descriptions.Item>
                <Descriptions.Item label="End Date">
                  {campaign.endDate}
                </Descriptions.Item>
              </Descriptions>
            </Card>
          </Col>

          <Col xs={24} lg={8}>
            <Card title="Performance Metrics">
              <Space direction="vertical" style={{ width: '100%' }} size="large">
                <Statistic 
                  title="Delivery Rate" 
                  value={deliveryRate} 
                  suffix="%" 
                  valueStyle={{ color: primaryColor }}
                />
                <Progress percent={Math.round(deliveryRate)} strokeColor={primaryColor} />
                
                <Statistic 
                  title="Open Rate" 
                  value={openRate} 
                  suffix="%" 
                  valueStyle={{ color: primaryColor }}
                />
                <Progress percent={Math.round(openRate)} strokeColor={primaryColor} />
                
                <Statistic 
                  title="Click Rate" 
                  value={clickRate} 
                  suffix="%" 
                  valueStyle={{ color: primaryColor }}
                />
                <Progress percent={Math.round(clickRate)} strokeColor={primaryColor} />
              </Space>
            </Card>

            <Card title="Quick Stats" style={{ marginTop: 16 }}>
              <Row gutter={[16, 16]}>
                <Col span={12}>
                  <Statistic title="Recipients" value={campaign.recipients} />
                </Col>
                <Col span={12}>
                  <Statistic title="Sent" value={campaign.sent} />
                </Col>
                <Col span={12}>
                  <Statistic title="Delivered" value={campaign.delivered} />
                </Col>
                <Col span={12}>
                  <Statistic title="Opened" value={campaign.opened} />
                </Col>
              </Row>
            </Card>
          </Col>
        </Row>
      </Space>
    </div>
  );
};
CAMPAIGNDETAILEOF

    # Settings page
    cat > packages/components/src/pages/Settings.tsx << 'SETTINGSEOF'
import { Card, Form, Input, Button, Select, Switch, Typography, Space, Divider } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useState } from 'react';

const { Title, Paragraph } = Typography;
const { Option } = Select;

export const Settings: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  
  const [form] = Form.useForm();
  const [loading, setLoading] = useState(false);

  const onFinish = async (values: any) => {
    setLoading(true);
    // Simulate API call
    await new Promise(resolve => setTimeout(resolve, 1000));
    console.log('Settings saved:', values);
    setLoading(false);
  };

  return (
    <div className="animate-fade-in">
      <Title level={2}>Settings</Title>
      <Paragraph>
        Manage your account settings and preferences.
      </Paragraph>

      <Card>
        <Form
          form={form}
          layout="vertical"
          onFinish={onFinish}
          initialValues={{
            clientName: themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template'),
            timezone: 'UTC',
            notifications: true,
            autoSave: true,
          }}
        >
          <Space direction="vertical" size="large" style={{ width: '100%' }}>
            <div>
              <Title level={4}>General Settings</Title>
              <Row gutter={[16, 0]}>
                <Col xs={24} md={12}>
                  <Form.Item
                    label="Client Name"
                    name="clientName"
                    rules={[{ required: true, message: 'Please enter client name' }]}
                  >
                    <Input placeholder="Enter client name" />
                  </Form.Item>
                </Col>
                <Col xs={24} md={12}>
                  <Form.Item
                    label="Timezone"
                    name="timezone"
                  >
                    <Select>
                      <Option value="UTC">UTC</Option>
                      <Option value="EST">Eastern Time</Option>
                      <Option value="PST">Pacific Time</Option>
                      <Option value="CST">Central Time</Option>
                    </Select>
                  </Form.Item>
                </Col>
              </Row>
            </div>

            <Divider />

            <div>
              <Title level={4}>Notification Settings</Title>
              <Form.Item
                name="notifications"
                valuePropName="checked"
                label="Enable Notifications"
              >
                <Switch />
              </Form.Item>
              <Form.Item
                name="autoSave"
                valuePropName="checked"
                label="Auto-save Changes"
              >
                <Switch />
              </Form.Item>
            </div>

            <Divider />

            <Form.Item>
              <Button 
                type="primary" 
                htmlType="submit" 
                loading={loading}
                style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
              >
                Save Settings
              </Button>
            </Form.Item>
          </Space>
        </Form>
      </Card>
    </div>
  );
};
SETTINGSEOF

    # Profile page
    cat > packages/components/src/pages/Profile.tsx << 'PROFILEEOF'
import { Card, Descriptions, Avatar, Button, Typography, Space } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';

const { Title, Paragraph } = Typography;

export const Profile: React.FC = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig } = useGetThemeConfigQuery(clientId);
  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const clientName = themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template');

  return (
    <div className="animate-fade-in">
      <Title level={2}>Profile</Title>
      <Paragraph>
        Your account information and preferences.
      </Paragraph>

      <Card>
        <Space direction="vertical" size="large" style={{ width: '100%' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <Avatar 
              size={64}
              style={{ 
                backgroundColor: primaryColor,
                fontSize: '24px'
              }}
            >
              {clientName.charAt(0).toUpperCase()}
            </Avatar>
            <div>
              <Title level={4} style={{ margin: 0 }}>{clientName}</Title>
              <Paragraph type="secondary" style={{ margin: 0 }}>
                SMS Marketing Client
              </Paragraph>
            </div>
          </div>

          <Descriptions 
            title="Account Information" 
            bordered 
            column={1}
            labelStyle={{ fontWeight: 'bold', width: '200px' }}
          >
            <Descriptions.Item label="Client ID">
              {clientId}
            </Descriptions.Item>
            <Descriptions.Item label="Primary Color">
              <Space>
                <div
                  style={{
                    width: '20px',
                    height: '20px',
                    backgroundColor: primaryColor,
                    borderRadius: '4px',
                    border: '1px solid #d9d9d9'
                  }}
                />
                {primaryColor}
              </Space>
            </Descriptions.Item>
            <Descriptions.Item label="API URL">
              {getEnv('VITE_API_URL', 'http://localhost:3001')}
            </Descriptions.Item>
            <Descriptions.Item label="Theme Features">
              {themeConfig?.features?.join(', ') || 'Standard features'}
            </Descriptions.Item>
          </Descriptions>

          <div>
            <Button 
              type="primary"
              style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
            >
              Edit Profile
            </Button>
          </div>
        </Space>
      </Card>
    </div>
  );
};
PROFILEEOF
}

create_client_template() {
    # Client template package.json - NO dependencies (they're in root)
    cat > apps/client-template/package.json << 'CLIENTPKGEOF'
{
  "name": "client-template",
  "private": true,
  "version": "0.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite --port 5173",
    "build": "tsc && vite build",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "preview": "vite preview"
  }
}
CLIENTPKGEOF

    # Client template config files
    cat > apps/client-template/tsconfig.json << 'CLIENTTSCONFIGEOF'
{
  "extends": "../../tsconfig.json",
  "compilerOptions": {
    "jsx": "react-jsx",
    "composite": true
  },
  "include": ["src", "vite.config.ts"],
  "references": [{ "path": "../../packages/config" }]
}
CLIENTTSCONFIGEOF

    cat > apps/client-template/tsconfig.node.json << 'CLIENTNODEEOF'
{
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
CLIENTNODEEOF

    cat > apps/client-template/vite.config.ts << 'CLIENTVITEEOF'
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
    host: true
  }
})
CLIENTVITEEOF

    cat > apps/client-template/tailwind.config.ts << 'CLIENTTAILWINDEOF'
import { themeConfig } from "@repo/theme";
export default themeConfig;
CLIENTTAILWINDEOF

    cat > apps/client-template/postcss.config.js << 'CLIENTPOSTCSSEOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
}
CLIENTPOSTCSSEOF

    cat > apps/client-template/index.html << 'CLIENTHTMLEOF'
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
CLIENTHTMLEOF

    # Environment files
    cat > apps/client-template/.env.example << 'CLIENTENVEXAMPLEEOF'
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=default
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=Template Client
CLIENTENVEXAMPLEEOF

    cat > apps/client-template/.env << 'CLIENTENVEOF'
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=default
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=Template Client
CLIENTENVEOF

    # Client template source files
    cat > apps/client-template/src/main.tsx << 'CLIENTMAINEOF'
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
CLIENTMAINEOF

    cat > apps/client-template/src/index.css << 'CLIENTCSSEOF'
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

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 6px;
}

::-webkit-scrollbar-track {
  background: #f1f1f1;
}

::-webkit-scrollbar-thumb {
  background: #c1c1c1;
  border-radius: 3px;
}

::-webkit-scrollbar-thumb:hover {
  background: #a8a8a8;
}

/* Animation classes */
.animate-fade-in {
  animation: fadeIn 0.5s ease-in-out;
}

.animate-slide-up {
  animation: slideUp 0.3s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes slideUp {
  from { 
    transform: translateY(10px);
    opacity: 0;
  }
  to { 
    transform: translateY(0);
    opacity: 1;
  }
}
CLIENTCSSEOF

    # Main App file with dynamic routing
    cat > apps/client-template/src/App.tsx << 'CLIENTAPPEOF'
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { ConfigProvider, Spin } from "@repo/ui";
import { useGetThemeConfigQuery } from "@repo/store";
import { getEnv } from "@repo/config";
import { createAntdTheme } from "@repo/ui";
import { 
  MainLayout, 
  Dashboard, 
  Campaigns, 
  CampaignDetail, 
  Settings, 
  Profile,
  ErrorBoundary,
  LoadingSpinner 
} from "@repo/components";
import "./App.css";

const AppContent = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig, isLoading, error } = useGetThemeConfigQuery(clientId);

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const antdTheme = createAntdTheme(primaryColor);

  // Enhanced router with dynamic routes
  const router = createBrowserRouter([
    {
      path: "/",
      element: <MainLayout />,
      errorElement: (
        <MainLayout>
          <ErrorBoundary>
            <div>Error occurred</div>
          </ErrorBoundary>
        </MainLayout>
      ),
      children: [
        {
          index: true,
          element: <Navigate to="/dashboard" replace />
        },
        {
          path: "dashboard",
          element: <Dashboard />
        },
        {
          path: "campaigns",
          children: [
            {
              index: true,
              element: <Campaigns />
            },
            {
              path: "new",
              element: <div>Create New Campaign - Coming Soon</div>
            },
            {
              path: ":id",
              element: <CampaignDetail />
            },
            {
              path: ":id/edit",
              element: <div>Edit Campaign - Coming Soon</div>
            }
          ]
        },
        {
          path: "subscribers",
          element: <div>Subscribers Management - Coming Soon</div>
        },
        {
          path: "analytics",
          element: <div>Analytics Dashboard - Coming Soon</div>
        },
        {
          path: "settings",
          element: <Settings />
        },
        {
          path: "profile",
          element: <Profile />
        },
        {
          path: "*",
          element: (
            <div style={{ textAlign: 'center', padding: '50px' }}>
              <h1>404 - Page Not Found</h1>
              <p>The page you are looking for doesn't exist.</p>
            </div>
          )
        }
      ]
    }
  ]);

  if (isLoading) {
    return <LoadingSpinner text="Loading theme configuration..." />;
  }

  if (error) {
    console.error('Failed to load theme:', error);
  }

  return (
    <ErrorBoundary>
      <ConfigProvider theme={antdTheme}>
        <RouterProvider router={router} />
      </ConfigProvider>
    </ErrorBoundary>
  );
};

export default function App() {
  return <AppContent />;
}
CLIENTAPPEOF

    cat > apps/client-template/src/App.css << 'CLIENTAPPCSSEOF'
#root {
  width: 100%;
}

/* Custom styles for the layout */
.ant-layout-header {
  line-height: 1.6 !important;
}

.ant-card {
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
  border: 1px solid #e8e8e8;
  transition: box-shadow 0.3s ease;
}

.ant-card:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
}

/* Responsive improvements */
@media (max-width: 768px) {
  .ant-layout-header {
    padding: 0 16px !important;
  }
  
  .ant-layout-content {
    padding: 16px !important;
  }
}

/* Custom button styles */
.ant-btn-primary {
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.ant-btn-primary:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 8px rgba(0,0,0,0.15);
}

/* Table improvements */
.ant-table-thead > tr > th {
  background-color: #fafafa;
  font-weight: 600;
}

/* Card header improvements */
.ant-card-head {
  borderBottom: '1px solid #f0f0f0',
}

.ant-card-head-title {
  font-weight: 600;
}
CLIENTAPPCSSEOF

    cat > apps/client-template/src/vite-env.d.ts << 'CLIENTVITEEOF'
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
CLIENTVITEEOF

    # Create public assets
    cat > apps/client-template/public/vite.svg << 'CLIENTSVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="iconify iconify--logos" width="31.88" height="32" preserveAspectRatio="xMidYMid meet" viewBox="0 0 256 257"><defs><linearGradient id="IconifyId1813088fe1fbc01fb466" x1="-.828%" x2="57.636%" y1="7.652%" y2="78.411%"><stop offset="0%" stop-color="#41D1FF"></stop><stop offset="100%" stop-color="#BD34FE"></stop></linearGradient><linearGradient id="IconifyId1813088fe1fbc01fb467" x1="43.376%" x2="50.316%" y1="2.242%" y2="89.03%"><stop offset="0%" stop-color="#FFEA83"></stop><stop offset="8.333%" stop-color="#FFDD35"></stop><stop offset="100%" stop-color="#FFA800"></stop></linearGradient></defs><path fill="url(#IconifyId1813088fe1fbc01fb466)" d="M255.153 37.938L134.897 252.976c-2.483 4.44-8.862 4.466-11.382.048L.875 37.958c-2.746-4.814 1.371-10.646 6.827-9.67l120.385 21.517a6.537 6.537 0 0 0 2.322-.004l117.867-21.483c5.438-.991 9.574 4.796 6.877 9.62Z"></path><path fill="url(#IconifyId1813088fe1fbc01fb467)" d="M185.432.063L96.44 17.501a3.268 3.268 0 0 0-2.634 3.014l-5.474 92.456a3.268 3.268 0 0 0 3.997 3.378l24.777-5.718c2.318-.535 4.413 1.507 3.936 3.838l-7.361 36.047c-.495 2.426 1.782 4.5 4.151 3.78l15.304-4.649c2.372-.72 4.652 1.36 4.15 3.788l-11.698 56.621c-.732 3.542 3.979 5.473 5.943 2.437l1.313-2.028l72.516-144.72c1.215-2.423-.88-5.186-3.54-4.672l-25.505 4.922c-2.396.462-4.435-1.77-3.759-4.114l16.646-57.705c.677-2.35-1.37-4.583-3.769-4.113Z"></path></svg>
CLIENTSVGEOF
}

create_scripts() {
    # create-client.sh
    cat > scripts/create-client.sh << 'SCRIPTEOF'
#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ Usage: $0 <client-name>${NC}"
    echo "   Example: $0 client-a"
    exit 1
fi

CLIENT_NAME="$1"
TEMPLATE_DIR="apps/client-template"
CLIENT_DIR="apps/$CLIENT_NAME"

if [ -d "$CLIENT_DIR" ]; then
    echo -e "${RED}❌ Client '$CLIENT_NAME' already exists!${NC}"
    exit 1
fi

if [ ! -d "$TEMPLATE_DIR" ]; then
    echo -e "${RED}❌ Template directory not found: $TEMPLATE_DIR${NC}"
    exit 1
fi

echo -e "${YELLOW}🚀 Creating new client: $CLIENT_NAME${NC}"

# Copy template
cp -r "$TEMPLATE_DIR" "$CLIENT_DIR"

# Update package.json name
sed -i.bak "s/\"client-template\"/\"$CLIENT_NAME\"/g" "$CLIENT_DIR/package.json"
rm -f "$CLIENT_DIR/package.json.bak"

# Update vite config port (increment from last client)
LAST_PORT=5173
CLIENT_COUNT=$(find apps -maxdepth 1 -name "client-*" -type d | wc -l)
NEW_PORT=$((LAST_PORT + CLIENT_COUNT))

sed -i.bak "s/port: 5173/port: $NEW_PORT/g" "$CLIENT_DIR/vite.config.ts"
rm -f "$CLIENT_DIR/vite.config.ts.bak"

# Create custom .env with client name
cat > "$CLIENT_DIR/.env" << ENVEOF
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=$CLIENT_NAME
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=$(echo $CLIENT_NAME | sed 's/client-//' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') Client
ENVEOF

echo -e "${GREEN}✅ Client '$CLIENT_NAME' created successfully!${NC}"
echo ""
echo -e "${YELLOW}🎨 Next steps:${NC}"
echo "   1. Edit $CLIENT_DIR/.env to customize colors and settings"
echo "   2. Start development: pnpm turbo run dev --filter=$CLIENT_NAME"
echo "   3. Or start all clients: pnpm dev"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
SCRIPTEOF

    chmod +x scripts/create-client.sh
}

create_mock_server() {
    # Mock API server
    cat > mock-server/theme-api.js << 'MOCKEOF'
const http = require('http');

const themes = {
  'client-blue': {
    primary_color: '#1890ff',
    client_name: 'Blue Client',
    features: ['SMS Campaigns', 'Analytics', 'Auto-Responses', 'Team Collaboration']
  },
  'client-purple': {
    primary_color: '#722ed1',
    client_name: 'Purple Client', 
    features: ['SMS Campaigns', 'Team Collaboration', 'API Access']
  },
  'client-green': {
    primary_color: '#52c41a',
    client_name: 'Green Client',
    features: ['SMS Campaigns', 'API Access', 'Webhooks', 'Advanced Analytics']
  },
  'client-red': {
    primary_color: '#ff4d4f',
    client_name: 'Red Client',
    features: ['SMS Campaigns', 'Auto-Responses', 'Bulk Messaging']
  },
  'default': {
    primary_color: '#1677ff',
    client_name: 'Default Client',
    features: ['SMS Campaigns', 'Basic Analytics']
  }
};

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Theme API endpoint
  if (req.url.startsWith('/api/theme/')) {
    const clientId = req.url.split('/').pop();
    const theme = themes[clientId] || themes.default;
    
    // Simulate network delay
    setTimeout(() => {
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(theme));
    }, 300);
    return;
  }

  // 404 for other routes
  res.writeHead(404);
  res.end(JSON.stringify({ error: 'Not found' }));
});

const PORT = 3001;
server.listen(PORT, () => {
  console.log('🎨 Mock Theme API server running on http://localhost:' + PORT);
  console.log('📋 Available themes:');
  Object.keys(themes).forEach(theme => {
    console.log(\`   - \${theme}: \${themes[theme].primary_color}\`);
  });
  console.log('\n💡 Use these client IDs in your .env files:');
  console.log('   VITE_CLIENT_ID=client-blue (or any theme name above)');
});
MOCKEOF

    cat > mock-server/package.json << 'MOCKPKGEOF'
{
  "name": "mock-server",
  "version": "1.0.0",
  "description": "Mock API server for theme configuration",
  "main": "theme-api.js",
  "scripts": {
    "start": "node theme-api.js"
  },
  "dependencies": {}
}
MOCKPKGEOF
}

# Main execution
create_project_structure

# Install dependencies
echo -e "${BLUE}📦 Installing dependencies...${NC}"
pnpm install

# Make scripts executable
chmod +x scripts/*.sh 2>/dev/null || true

echo -e "${GREEN}✅ sms-turbo installed successfully!${NC}"
echo ""
echo -e "${YELLOW}🎯 Quick Start:${NC}"
echo -e "   ${BLUE}cd $PROJECT_NAME${NC}"
echo -e "   ${BLUE}pnpm dev${NC}                         # Start template client"
echo ""
echo -e "${YELLOW}🎨 Create new clients:${NC}"
echo -e "   ${BLUE}pnpm create-client client-blue${NC}"
echo -e "   ${BLUE}pnpm create-client client-purple${NC}"
echo -e "   ${BLUE}pnpm create-client client-green${NC}"
echo ""
echo -e "${YELLOW}🚀 Start mock API server:${NC}"
echo -e "   ${BLUE}pnpm mock-api${NC}                    # In a separate terminal"
echo ""
echo -e "${YELLOW}🔧 Run specific client:${NC}"
echo -e "   ${BLUE}pnpm turbo run dev --filter=client-template${NC}"
echo ""
echo -e "${GREEN}📚 Available URLs:${NC}"
echo -e "   ${BLUE}http://localhost:5173${NC}            # client-template"
echo -e "   ${BLUE}http://localhost:3001${NC}            # mock API server"
echo ""
echo -e "${GREEN}📁 Project Structure:${NC}"
echo -e "   ${BLUE}node_modules/${NC}                    # SINGLE node_modules for entire monorepo"
echo -e "   ${BLUE}apps/client-template/${NC}            # Template client app"
echo -e "   ${BLUE}packages/*/${NC}                      # Shared packages"
echo -e "   ${BLUE}scripts/${NC}                         # Utility scripts"
echo ""
echo -e "${GREEN}💾 Space Efficient:${NC}"
echo -e "   ✅ Single node_modules folder"
echo -e "   ✅ Shared dependencies across all packages"
echo -e "   ✅ Fast installation with pnpm"
echo -e "   ✅ Efficient disk space usage"
echo ""
echo -e "${GREEN}Happy turbo-charging! 🚀${NC}"