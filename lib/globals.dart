import 'package:flutter/material.dart';
import 'package:fungjai_app_new/services/emotion_classifier_service.dart';

// ที่เก็บของส่วนกลางของเรา

// 1. กุญแจสำหรับควบคุมการเปลี่ยนหน้า (Navigator) ของแอป
//    ใครๆ ก็สามารถเรียกใช้ navigatorKey เพื่อสั่งเปลี่ยนหน้าได้
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 2. ตัววิเคราะห์อารมณ์
//    เราสร้างตัวนี้ไว้ที่นี่ครั้งเดียว เพื่อให้ทุกหน้าเรียกใช้ตัวเดียวกันได้เลย
//    ไม่ต้องไปสร้างใหม่ทุกครั้งที่เปิดหน้า
final EmotionClassifierService classifier = EmotionClassifierService();
