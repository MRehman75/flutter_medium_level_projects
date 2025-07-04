# split_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Screenshots

| Screen            | Description                                 | Image |
|-------------------|---------------------------------------------|-------|
| Login             | User login screen with animated branding     | ![Login](images/login.jfif) |
| Register          | User registration screen                    | ![Register](images/register.jfif) |
| Home              | Home screen showing user's groups           | ![Home](images/home.jfif) |
| Profile           | User profile with balance and group info    | ![Profile](images/profile.jfif) |
| Group List        | Group list and navigation                   | ![Grouppro](images/grouppro.jfif) |
| Create Group      | Create a new group                          | ![Create Group](images/creategroup.jfif) |
| Group Detail      | Group details and members                   | ![Group Detail](images/group_detail.jfif) |
| Add Expense       | Add a new expense to a group                | ![Add Expense](images/add%20expence.jfif) |
| Expense History   | View all group expenses                     | ![Expense History](images/expense%20his.jfif) |
| Group Dashboard   | Dashboard with balances and shares          | ![Group Dashboard](images/groupdash.jfif) |
| Group Chat        | Real-time group chat                        | ![Group Chat](images/groupchat.jfif) |
| Invite User       | Invite users to join a group                | ![Invite User](images/inviteu.jfif) |
| Forgot Password   | Password reset flow                         | ![Forgot Password](images/forget.jfif) |

## Demo Video

<div style="max-width: 100%;">
  <video width="100%" style="max-width: 100%; height: auto;" controls>
    <source src="video/demovideo.mp4" type="video/mp4">
    Your browser does not support the video tag. [View the demo video here.](video/demovideo.mp4)
  </video>
</div>

> The video demonstrates the full app flow: registration, login, group management, adding expenses, dashboard, chat, and more.

## Detail

SplitShare is a modern, cross-platform Flutter app for managing group expenses, splitting bills, and tracking balances. It features real-time group chat, notifications, and a beautiful, animated UI. The app is powered by Firebase for authentication, data storage, and notifications.

## Work Flow

1. **User Registration & Login:**
   - Users register with email, password, and unique username.
   - Email verification and password reset supported.
   - Login only after email verification.
2. **Profile Management:**
   - View and edit profile (username, email).
   - Add cash to balance.
   - See pending group invites and accept/reject them.
3. **Group Management:**
   - Create groups, invite users by username/email.
   - Admin manages members and invites.
   - View group details, members, and expense history.
4. **Expense Management:**
   - Add expenses to groups (split equally).
   - Dashboard shows balances, shares, and who owes whom.
   - Only admin can delete expenses.
5. **Group Chat:**
   - Real-time chat for each group.
6. **Notifications:**
   - In-app notifications for invites, expenses, and group events.
7. **Navigation:**
   - Modern bottom navigation and menu for quick access to all features.

## Project Structure

```
split_app/
  lib/
    main.dart                # App entry point, routes
    auth/
      login_page.dart        # Login UI & logic
      register_page.dart     # Registration UI & logic
      profile_page.dart      # Profile, edit, cash, invites
      home_page.dart         # Home, group list
      group_page.dart        # Group details, members, expenses
      add_expense_page.dart  # Add expense form
      group_dashboard_page.dart # Dashboard, balances
      group_chat_page.dart   # Real-time chat
      invite_user_page.dart  # Invite users to group
      create_group_page.dart # Create new group
      auth_page.dart         # Auth flow
  android/ios/web/linux/macos/windows/ # Platform support
  images/                   # Screenshots
  video/                    # Demo video
```

## Technology Used

- **Flutter** (cross-platform UI)
- **Firebase Auth** (user authentication, email verification, password reset)
- **Cloud Firestore** (real-time database for users, groups, expenses, chat, notifications)
- **Google Fonts** (modern typography)
- **Wave** (animated backgrounds)
- **Lottie** (optional for animations)
- **Provider** (state management)
- **Other:** intl, fl_chart, share_plus, cached_network_image, badges, pdf, printing, etc.
- **Platform Support:** Android, iOS, Web, Windows, MacOS, Linux

## Project Working (Main Features)

- **Authentication:** Secure registration, login, email verification, password reset.
- **Profile:** Edit username/email, add cash, view invites.
- **Groups:** Create, join, invite, and manage groups.
- **Expenses:** Add, view, and split expenses; dashboard for balances.
- **Chat:** Real-time group chat for collaboration.
- **Notifications:** In-app notifications for group events and expenses.
- **Modern UI:** Animated backgrounds, Google Fonts, responsive design, beautiful cards and buttons.
- **Navigation:** Bottom navigation bar, menu, and named routes for smooth UX.

---

Feel free to explore the code, run the app, and check out the screenshots and demo video above!
