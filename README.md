# 🚀 SMS Turbo - Multi-Client Monorepo

A powerful Turborepo monorepo for multi-client SMS applications with dynamic theming, shared components, and API-driven configuration.

## ✨ Features

- 🎨 **Dynamic Theming**: API-driven color configuration for each client
- 📱 **Multi-Client Architecture**: Easily manage multiple client applications
- 🏗️ **Shared Packages**: Reusable UI components, routing, state management
- ⚡ **Turbo Powered**: Fast builds and development with Turborepo
- 🎪 **Ant Design**: Enterprise-grade UI components with dynamic themes
- 🎨 **Tailwind CSS**: Utility-first CSS framework
- 🔄 **Redux Toolkit**: State management with RTK Query for API calls
- 📊 **Ready-to-Use Templates**: Dashboard, campaigns, and layout components
- 🔧 **Shared Components**: All components come from shared packages

## 🚀 Quick Installation

### One-Command Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/codeninja-404/turbo-gist/main/install.sh | bash
```

### With Custom Project Name

```bash
curl -fsSL https://raw.githubusercontent.com/codeninja-404/turbo-gist/main/install.sh | bash -s my-sms-app
```

## 🛠️ Manual Installation

```bash
# Clone the repository
git clone https://github.com/codeninja-404/turbo-gist.git
cd turbo-gist

# Install dependencies
pnpm install

# Start development
pnpm dev
```

## 📁 Project Structure

```
sms-turbo/
├── apps/
│   ├── client-template/          # Template application
│   │   ├── src/                 # App-specific code only
│   │   └── *.env               # Environment configuration
│   └── your-client/            # Your custom clients
├── packages/
│   ├── components/             # Shared components (Header, Footer, Pages, Layout)
│   ├── ui/                     # Ant Design components
│   ├── theme/                  # Tailwind & theme configuration
│   ├── router/                 # React Router setup
│   ├── utils/                  # Utility functions
│   ├── config/                 # Environment configuration
│   └── store/                  # Redux store & API logic
├── scripts/
│   └── create-client.sh        # Client creation script
└── mock-server/
    └── theme-api.js           # Mock API server
```

## 🎨 Creating Clients

### Using the Script (Recommended)

```bash
# Create a new client
pnpm create-client client-blue

# IMPORTANT: After creating, run pnpm install to update the lockfile
pnpm install

# Create multiple clients
pnpm create-client client-purple
pnpm install
pnpm create-client client-green
pnpm install
pnpm create-client client-red
pnpm install
```

### Manual Creation

```bash
# Copy template
cp -r apps/client-template apps/your-client-name

# Update package.json name
cd apps/your-client-name
# Edit package.json and change "client-template" to "your-client-name"

# Configure environment
cp .env.example .env
# Edit .env with your settings

# Go back to root and update lockfile
cd ../..
pnpm install
```

## 🚀 Development

### Start All Clients

```bash
pnpm dev
```

### Start Specific Client

```bash
pnpm turbo run dev --filter=client-blue
```

### Start Mock API Server

```bash
# In a separate terminal
pnpm mock-api
```

### Build for Production

```bash
pnpm build
```

**Note:** Avoid paths with spaces in your project directory to prevent resolution issues.

## 🎯 Shared Components

All components are shared from `@repo/components` package:

### Layout Components

- **Header**: Dynamic header with navigation and theme display
- **Footer**: Consistent footer across all pages
- **MainLayout**: Complete layout structure

### Pages

- **Dashboard**: Overview with statistics and quick actions
- **Campaigns**: Campaign management with data table

### Benefits

- ✅ **Consistent UI**: Same components used across all clients
- ✅ **Easy Updates**: Update once in packages, all clients get changes
- ✅ **Type Safety**: Shared TypeScript definitions
- ✅ **Better Organization**: Clear separation of concerns

## 🔧 Configuration

### Environment Variables

Each client can be configured via `.env` file:

```env
VITE_API_URL=http://localhost:3001    # API base URL
VITE_CLIENT_ID=client-blue           # Client identifier for API
VITE_PRIMARY_COLOR=#1677ff           # Fallback primary color
VITE_CLIENT_NAME=Blue Client         # Client display name
```

### Theme Configuration

Themes are fetched from the API based on `VITE_CLIENT_ID`:

- Primary color
- Client name
- Available features
- Logo URL (optional)

## 🎨 Customization

### Adding New Shared Components

1. Create component in `packages/components/src/`
2. Export from `packages/components/src/index.ts`
3. Import in your client apps: `import { Component } from '@repo/components'`

### Adding New Pages

1. Create page component in `packages/components/src/pages/`
2. Export from `packages/components/src/index.ts`
3. Add route in client `App.tsx`

### Modifying Themes

1. Update mock server themes in `mock-server/theme-api.js`
2. Or connect to your real API
3. Colors are automatically applied to Ant Design and custom components

## 🔌 API Integration

### Mock Server

The included mock server provides theme configuration:

- Endpoint: `GET /api/theme/:clientId`
- Returns: Theme configuration JSON

### Real API Integration

1. Update `VITE_API_URL` in client `.env` files
2. Ensure your API returns the expected format
3. Update API logic in `packages/store/src/api/themeApi.ts`

## 📦 Available Scripts

- `pnpm dev` - Start development servers
- `pnpm build` - Build for production
- `pnpm lint` - Run linting
- `pnpm test` - Run tests
- `pnpm create-client` - Create new client
- `pnpm mock-api` - Start mock API server

## 🛠️ Requirements

- Node.js 20.0.0 or higher
- pnpm 9.0.0 or higher

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Support

If you encounter any issues:

1. Check the troubleshooting section in documentation
2. Search existing GitHub issues
3. Create a new issue with detailed information

---

**Happy coding! 🚀**
