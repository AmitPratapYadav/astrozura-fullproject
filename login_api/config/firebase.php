<?php

return [
    'project_id' => env('FIREBASE_PROJECT_ID'),
    'credentials_path' => env('FIREBASE_CREDENTIALS_PATH'),
    'web_push_link' => env('FIREBASE_WEB_PUSH_LINK', 'http://localhost:5173/live'),
    'web_push_icon' => env('FIREBASE_WEB_PUSH_ICON', '/vite.svg'),
    'web_push_badge' => env('FIREBASE_WEB_PUSH_BADGE', '/vite.svg'),
    'messaging_scope' => 'https://www.googleapis.com/auth/firebase.messaging',
];
