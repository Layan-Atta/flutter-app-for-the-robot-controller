<?php
// ⚙️ إعدادات قاعدة البيانات
$servername = "localhost";
$username = "root";
$password = "root"; // ⚠️ ضع كلمة المرور هنا
$dbname = "robot_control";

// السماح بطلبات من أي مصدر (CORS)
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

// معالجة OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// الاتصال بقاعدة البيانات
$conn = new mysqli($servername, $username, $password);

// التحقق من الاتصال
if ($conn->connect_error) {
    die(json_encode(['error' => 'فشل الاتصال: ' . $conn->connect_error]));
}

// إنشاء قاعدة البيانات إذا لم تكن موجودة
$conn->query("CREATE DATABASE IF NOT EXISTS $dbname");
$conn->select_db($dbname);

// إنشاء جدول angles إذا لم يكن موجوداً
$createTableSQL = "CREATE TABLE IF NOT EXISTS angles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    servo1 INT NOT NULL,
    servo2 INT NOT NULL,
    servo3 INT NOT NULL,
    servo4 INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)";
$conn->query($createTableSQL);

// إنشاء جدول current_pose لتخزين الوضعية الحالية (للتشغيل)
$createCurrentPoseSQL = "CREATE TABLE IF NOT EXISTS current_pose (
    id INT PRIMARY KEY DEFAULT 1,
    servo1 INT NOT NULL,
    servo2 INT NOT NULL,
    servo3 INT NOT NULL,
    servo4 INT NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)";
$conn->query($createCurrentPoseSQL);

// معالجة الطلبات
$action = $_REQUEST['action'] ?? 'get_current';

switch ($action) {
    
    // 1. جلب كل الوضعيات المحفوظة (للعرض في التطبيق)
    case 'fetch':
        $result = $conn->query("SELECT id, servo1, servo2, servo3, servo4, created_at FROM angles ORDER BY id DESC");
        $poses = [];
        
        if ($result->num_rows > 0) {
            while ($row = $result->fetch_assoc()) {
                $poses[] = $row;
            }
        }
        
        echo json_encode(['success' => true, 'poses' => $poses]);
        break;
    
    // 2. حفظ وضعية جديدة
    case 'save':
        $servo1 = intval($_POST['servo1']);
        $servo2 = intval($_POST['servo2']);
        $servo3 = intval($_POST['servo3']);
        $servo4 = intval($_POST['servo4']);
        
        $stmt = $conn->prepare("INSERT INTO angles (servo1, servo2, servo3, servo4) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("iiii", $servo1, $servo2, $servo3, $servo4);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'تم الحفظ بنجاح', 'id' => $stmt->insert_id]);
        } else {
            echo json_encode(['success' => false, 'error' => $stmt->error]);
        }
        $stmt->close();
        break;
    
    // 3. تشغيل وضعية (تخزينها في current_pose)
    case 'run':
        $servo1 = intval($_POST['servo1']);
        $servo2 = intval($_POST['servo2']);
        $servo3 = intval($_POST['servo3']);
        $servo4 = intval($_POST['servo4']);
        
        // حذف الصف الحالي وإدراج الجديد
        $conn->query("DELETE FROM current_pose WHERE id = 1");
        
        $stmt = $conn->prepare("INSERT INTO current_pose (id, servo1, servo2, servo3, servo4) VALUES (1, ?, ?, ?, ?)");
        $stmt->bind_param("iiii", $servo1, $servo2, $servo3, $servo4);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'تم الإرسال للروبوت']);
        } else {
            echo json_encode(['success' => false, 'error' => $stmt->error]);
        }
        $stmt->close();
        break;
    
    // 4. حذف وضعية
    case 'delete':
        $id = intval($_POST['id']);
        
        $stmt = $conn->prepare("DELETE FROM angles WHERE id = ?");
        $stmt->bind_param("i", $id);
        
        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'تم الحذف']);
        } else {
            echo json_encode(['success' => false, 'error' => $stmt->error]);
        }
        $stmt->close();
        break;
    
    // 5. جلب الوضعية الحالية (لـ ESP)
    case 'get_current':
    default:
        $result = $conn->query("SELECT servo1, servo2, servo3, servo4 FROM current_pose WHERE id = 1 LIMIT 1");
        
        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();
            // إرجاع البيانات بصيغة نصية بسيطة للـ ESP
            header('Content-Type: text/plain');
            echo $row['servo1'] . ',' . $row['servo2'] . ',' . $row['servo3'] . ',' . $row['servo4'];
        } else {
            // إذا لم توجد بيانات، إرجاع القيم الافتراضية
            header('Content-Type: text/plain');
            echo "90,90,90,90";
        }
        break;
}

$conn->close();
?>