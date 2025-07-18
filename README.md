<<<<<<< HEAD
# 🏨 Resort Booking Tracker

A luxurious Flutter-based resort management application designed for modern hospitality businesses. This app provides comprehensive booking management, guest tracking, and analytics with a premium user interface.

![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue)
![Dart](https://img.shields.io/badge/Dart-3.3.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## ✨ Features

### 🎨 **Luxury UI/UX Design**

- Premium gradient backgrounds with modern color palette
- Poppins font family for elegant typography
- Smooth animations and transitions
- Card-based design with shadows and rounded corners
- Responsive design for multiple screen sizes

### 🏠 **Room Management**

- Visual room status tracking (Available, Occupied, Cleaning, Maintenance)
- Room type and number management
- Current guest information display
- Interactive room cards with status indicators
- Statistics dashboard for room occupancy

### 👥 **Guest Management**

- Comprehensive guest profiles with contact information
- Booking history tracking
- Guest search and filtering capabilities
- Easy add/edit/delete operations
- Guest-to-booking relationship mapping

### 💰 **Payment & Invoicing**

- Payment status tracking
- Revenue analytics
- Invoice generation system
- Payment method management
- Financial reporting dashboard

### 📊 **Analytics Dashboard**

- Interactive pie charts for room distribution
- Revenue trend analysis with line charts
- Occupancy rate tracking
- Booking statistics
- Visual KPI indicators

### 📅 **Calendar Integration**

- Visual booking calendar with TableCalendar
- Room-specific booking views
- Date-based booking filtering
- Booking status indicators
- Quick booking creation

### 🧭 **Navigation**

- Unified bottom navigation bar across all pages
- Smooth page transitions
- Drawer navigation for secondary features
- Intuitive user flow

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.19.0 or higher)
- Dart SDK (3.3.0 or higher)
- Android Studio / VS Code with Flutter plugin
- Git

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/ashokthaniyath/bookingtracker.git
   cd bookingtracker
   ```

2. **Navigate to the app directory**

   ```bash
   cd clietapp
   ```

3. **Install dependencies**

   ```bash
   flutter pub get
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Screenshots

_Screenshots will be added soon_

## 🏗️ Architecture

### **State Management**

- Uses Hive for local data persistence
- ValueListenableBuilder for reactive UI updates
- StatefulWidget with AnimationController for UI animations

### **Data Models**

- `Room`: Room information and status
- `Guest`: Guest profile and contact details
- `Booking`: Booking details linking guests and rooms
- `Payment`: Payment tracking and status

### **Navigation Structure**

```
MainScaffold
├── HomeDashboardScreen (Dashboard)
├── RoomManagementPage (Rooms)
├── GuestManagementPage (Guests)
├── PaymentsPage (Invoices)
└── DashboardAnalyticsScreen (Analytics)
```

## 🎨 Design System

### **Color Palette**

- Primary Blue: `#1E3A8A`
- Secondary Blue: `#3B82F6`
- Success Green: `#14B8A6`
- Warning Yellow: `#EAB308`
- Error Red: `#F43F5E`
- Neutral Gray: `#64748B`

### **Typography**

- Primary Font: Poppins
- Font Weights: 400 (Regular), 500 (Medium), 600 (SemiBold), 700 (Bold)

### **Spacing System**

- Base Unit: 4px
- Common Spacing: 8px, 12px, 16px, 20px, 24px

## 📦 Dependencies

### **Core**

- `flutter`: SDK
- `hive_flutter`: Local database
- `hive_generator`: Code generation for Hive

### **UI/UX**

- `google_fonts`: Typography
- `flutter_staggered_animations`: Animations
- `fl_chart`: Charts and graphs
- `table_calendar`: Calendar widget

### **Utilities**

- `intl`: Internationalization
- `url_launcher`: External link handling
- `firebase_core`: Firebase integration (optional)

## 🛠️ Development

### **Adding New Features**

1. Create new model classes in `lib/models/`
2. Generate Hive adapters using build_runner
3. Implement screens in `lib/screens/`
4. Add navigation routes in `main.dart`
5. Update UI components in `lib/widgets/`

### **Code Generation**

```bash
flutter packages pub run build_runner build
```

### **Testing**

```bash
flutter test
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**Ashok Thaniyath**

- GitHub: [@ashokthaniyath](https://github.com/ashokthaniyath)
- Email: ashokthaniyath@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Hive team for efficient local storage
- FL Chart for beautiful charts
- Google Fonts for typography options
- Table Calendar for calendar functionality

## 🗺️ Roadmap

- [ ] Firebase integration for cloud sync
- [ ] Multi-language support
- [ ] Dark theme implementation
- [ ] Export functionality for reports
- [ ] Push notifications
- [ ] Offline mode improvements
- [ ] Advanced filtering and search
- [ ] Email integration for bookings
- [ ] PDF generation for invoices
- [ ] User authentication system

---

**Built with ❤️ using Flutter**
=======
# bookingtrackerupdate
>>>>>>> dc5b4c2a28dc95028e493f6db7dd1f218da0b6f9
