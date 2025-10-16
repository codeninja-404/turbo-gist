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
    echo -e "${YELLOW}⚠️  Directory $PROJECT_NAME already exists. Using existing directory.${NC}"
else
    mkdir -p "$PROJECT_NAME"
fi

cd "$PROJECT_NAME"

# Download and extract the project structure
echo -e "${BLUE}📥 Downloading project template...${NC}"

# Create the complete project structure
create_project_structure() {
    # Create root structure
    mkdir -p apps/client-template/{public,src} 
    mkdir -p packages/{config,router,theme,ui,utils,store,components}/src
    mkdir -p packages/store/src/{api,slices}
    mkdir -p packages/components/src/{pages,layout}
    mkdir -p scripts mock-server

    # Create root files
    cat > package.json << 'ROOT_EOF'
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
    "react-redux": "^9.1.2"
  },
  "packageManager": "pnpm@9.12.2",
  "engines": {
    "node": ">=20.0.0"
  }
}
ROOT_EOF

    cat > pnpm-workspace.yaml << 'EOF'
packages:
  - "apps/*"
  - "packages/*"
EOF

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

    # Create shared packages
    create_shared_packages
    # Create client template
    create_client_template
    # Create scripts
    create_scripts
    # Create mock server
    create_mock_server
}

create_shared_packages() {
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

    # packages/components
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

    # Header component
    cat > packages/components/src/Header.tsx << 'EOF'
import { Layout, Typography, Space, Button } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
import { useNavigate, useLocation } from 'react-router-dom';

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

  const primaryColor = themeConfig?.primaryColor || getEnv('VITE_PRIMARY_COLOR', '#1677ff');
  const clientName = themeConfig?.clientName || getEnv('VITE_CLIENT_NAME', 'Template');

  const handleMenuClick = (key: string) => {
    if (onMenuClick) {
      onMenuClick(key);
    } else {
      navigate(`/${key}`);
    }
  };

  const getCurrentPage = () => {
    return currentPage || location.pathname.replace('/', '') || 'dashboard';
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
        <Button 
          type="text" 
          style={{ color: 'white' }}
          onClick={() => handleMenuClick('settings')}
        >
          Settings
        </Button>
      </Space>
    </AntHeader>
  );
};
EOF

    # Footer component
    cat > packages/components/src/Footer.tsx << 'EOF'
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

    # MainLayout component
    cat > packages/components/src/MainLayout.tsx << 'EOF'
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

    # Dashboard page
    cat > packages/components/src/pages/Dashboard.tsx << 'EOF'
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
        Welcome to your SMS marketing dashboard. Here you can manage campaigns, 
        track performance, and analyze your messaging data.
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
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic title="Delivery Rate" value={98.2} suffix="%" valueStyle={{ color: primaryColor }} />
          </Card>
        </Col>
        <Col xs={24} sm={12} md={6}>
          <Card>
            <Statistic title="Active Subscribers" value={2450} valueStyle={{ color: primaryColor }} />
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]}>
        <Col xs={24} lg={12}>
          <Card 
            title="Recent Performance" 
            extra={<Button type="link" style={{ color: primaryColor }}>View All</Button>}
          >
            <Space direction="vertical" style={{ width: '100%' }}>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span>Campaign Delivery</span>
                  <span>92%</span>
                </div>
                <Progress percent={92} strokeColor={primaryColor} />
              </div>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span>Message Engagement</span>
                  <span>78%</span>
                </div>
                <Progress percent={78} strokeColor={primaryColor} />
              </div>
              <div>
                <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
                  <span>Subscriber Growth</span>
                  <span>65%</span>
                </div>
                <Progress percent={65} strokeColor={primaryColor} />
              </div>
            </Space>
          </Card>
        </Col>
        
        <Col xs={24} lg={12}>
          <Card 
            title="Quick Actions" 
            extra={<Button type="link" style={{ color: primaryColor }}>More</Button>}
          >
            <Space direction="vertical" style={{ width: '100%' }}>
              <Button 
                type="primary" 
                block 
                style={{ backgroundColor: primaryColor, borderColor: primaryColor }}
                onClick={() => window.location.href = '/campaigns'}
              >
                Create New Campaign
              </Button>
              <Button block>Manage Subscribers</Button>
              <Button block>View Analytics</Button>
              <Button block>Account Settings</Button>
            </Space>
          </Card>
        </Col>
      </Row>

      {themeConfig?.features && themeConfig.features.length > 0 && (
        <Card title="Available Features" style={{ marginTop: 24 }}>
          <Row gutter={[16, 16]}>
            {themeConfig.features.map((feature, index) => (
              <Col xs={24} sm={12} md={8} key={index}>
                <Card size="small" style={{ borderLeft: `4px solid ${primaryColor}` }}>
                  <span style={{ color: primaryColor }}>✓</span> {feature}
                </Card>
              </Col>
            ))}
          </Row>
        </Card>
      )}
    </div>
  );
};
EOF

    # Campaigns page
    cat > packages/components/src/pages/Campaigns.tsx << 'EOF'
import { Card, Table, Button, Tag, Space, Typography, Input } from '@repo/ui';
import { useGetThemeConfigQuery } from '@repo/store';
import { getEnv } from '@repo/config';
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
          <Button type="link" size="small" style={{ color: primaryColor }}>
            Edit
          </Button>
          <Button type="link" size="small" danger>
            Delete
          </Button>
        </Space>
      ),
    },
  ];

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
        />
      </Card>
    </div>
  );
};
EOF
}

create_client_template() {
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
    "@reduxjs/toolkit": "^2.2.7",
    "react-redux": "^9.1.2",
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
EOF

    # Main App file (simplified - uses shared components)
    cat > apps/client-template/src/App.tsx << 'EOF'
import { createBrowserRouter, RouterProvider, Navigate } from 'react-router-dom';
import { ConfigProvider, Spin } from "@repo/ui";
import { useGetThemeConfigQuery } from "@repo/store";
import { getEnv } from "@repo/config";
import { createAntdTheme } from "@repo/ui";
import { MainLayout, Dashboard, Campaigns } from "@repo/components";
import "./App.css";

const AppContent = () => {
  const clientId = getEnv('VITE_CLIENT_ID', 'default');
  const { data: themeConfig, isLoading, error } = useGetThemeConfigQuery(clientId);

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

  if (error) {
    console.error('Failed to load theme:', error);
  }

  return (
    <ConfigProvider theme={antdTheme}>
      <RouterProvider router={createBrowserRouter([
        {
          path: "/",
          element: <MainLayout />,
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
              element: <Campaigns />
            },
            {
              path: "settings",
              element: <div>Settings Page - Coming Soon</div>
            },
            {
              path: "*",
              element: <Navigate to="/dashboard" replace />
            }
          ]
        }
      ])} />
    </ConfigProvider>
  );
};

export default function App() {
  return <AppContent />;
}
EOF

    cat > apps/client-template/src/App.css << 'EOF'
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
    cat > apps/client-template/public/vite.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" aria-hidden="true" role="img" class="iconify iconify--logos" width="31.88" height="32" preserveAspectRatio="xMidYMid meet" viewBox="0 0 256 257"><defs><linearGradient id="IconifyId1813088fe1fbc01fb466" x1="-.828%" x2="57.636%" y1="7.652%" y2="78.411%"><stop offset="0%" stop-color="#41D1FF"></stop><stop offset="100%" stop-color="#BD34FE"></stop></linearGradient><linearGradient id="IconifyId1813088fe1fbc01fb467" x1="43.376%" x2="50.316%" y1="2.242%" y2="89.03%"><stop offset="0%" stop-color="#FFEA83"></stop><stop offset="8.333%" stop-color="#FFDD35"></stop><stop offset="100%" stop-color="#FFA800"></stop></linearGradient></defs><path fill="url(#IconifyId1813088fe1fbc01fb466)" d="M255.153 37.938L134.897 252.976c-2.483 4.44-8.862 4.466-11.382.048L.875 37.958c-2.746-4.814 1.371-10.646 6.827-9.67l120.385 21.517a6.537 6.537 0 0 0 2.322-.004l117.867-21.483c5.438-.991 9.574 4.796 6.877 9.62Z"></path><path fill="url(#IconifyId1813088fe1fbc01fb467)" d="M185.432.063L96.44 17.501a3.268 3.268 0 0 0-2.634 3.014l-5.474 92.456a3.268 3.268 0 0 0 3.997 3.378l24.777-5.718c2.318-.535 4.413 1.507 3.936 3.838l-7.361 36.047c-.495 2.426 1.782 4.5 4.151 3.78l15.304-4.649c2.372-.72 4.652 1.36 4.15 3.788l-11.698 56.621c-.732 3.542 3.979 5.473 5.943 2.437l1.313-2.028l72.516-144.72c1.215-2.423-.88-5.186-3.54-4.672l-25.505 4.922c-2.396.462-4.435-1.77-3.759-4.114l16.646-57.705c.677-2.35-1.37-4.583-3.769-4.113Z"></path></svg>
EOF
}

create_scripts() {
    # create-client.sh
    cat > scripts/create-client.sh << 'EOF'
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

# Create custom .env with client name
cat > "$CLIENT_DIR/.env" << ENV_EOF
VITE_API_URL=http://localhost:3001
VITE_CLIENT_ID=$CLIENT_NAME
VITE_PRIMARY_COLOR=#1677ff
VITE_CLIENT_NAME=$(echo $CLIENT_NAME | sed 's/client-//' | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}') Client
ENV_EOF

echo -e "${GREEN}✅ Client '$CLIENT_NAME' created successfully!${NC}"
echo ""
echo -e "${YELLOW}🎨 Next steps:${NC}"
echo "   1. Edit $CLIENT_DIR/.env to customize colors and settings"
echo "   2. Start development: pnpm turbo run dev --filter=$CLIENT_NAME"
echo "   3. Or start all clients: pnpm dev"
echo ""
echo -e "${GREEN}Happy coding! 🎉${NC}"
EOF

    chmod +x scripts/create-client.sh
}

create_mock_server() {
    # Mock API server
    cat > mock-server/theme-api.js << 'EOF'
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
    console.log(`   - ${theme}: ${themes[theme].primary_color}`);
  });
  console.log('\n💡 Use these client IDs in your .env files:');
  console.log('   VITE_CLIENT_ID=client-blue (or any theme name above)');
});
EOF

    cat > mock-server/package.json << 'EOF'
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
EOF
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
echo -e "   ${BLUE}pnpm dev${NC}                         # Start all clients"
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
echo -e "${GREEN}📚 Full documentation:${NC}"
echo -e "   Check README.md for detailed instructions"
echo ""
echo -e "${GREEN}Happy turbo-charging! 🚀${NC}"