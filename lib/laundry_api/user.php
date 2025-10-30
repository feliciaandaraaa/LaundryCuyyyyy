<?php
include 'config.php';

$method = $_SERVER['REQUEST_METHOD'];

switch($method) {
    case 'GET':
        // Get all users
        $query = "SELECT * FROM user";
        $result = $conn->query($query);
        
        $users = [];
        while($row = $result->fetch_assoc()) {
            $users[] = $row;
        }
        echo json_encode($users);
        break;
        
    case 'POST':
        // Add new user
        $data = json_decode(file_get_contents("php://input"));
        
        if(isset($data->nama) && isset($data->email) && isset($data->password) && isset($data->no_handphone) && isset($data->alamat)) {
            $nama = $data->nama;
            $email = $data->email;
            $password = password_hash($data->password, PASSWORD_DEFAULT);
            $no_handphone = $data->no_handphone;
            $alamat = $data->alamat;
            
            $query = "INSERT INTO user (nama, email, password, no_handphone, alamat) VALUES (?, ?, ?, ?, ?)";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("sssss", $nama, $email, $password, $no_handphone, $alamat);
            
            if($stmt->execute()) {
                echo json_encode(["message" => "User added successfully"]);
            } else {
                echo json_encode(["error" => "Failed to add user"]);
            }
        }
        break;
        
    case 'PUT':
        // Update user
        $data = json_decode(file_get_contents("php://input"));
        
        if(isset($data->id_user) && isset($data->nama) && isset($data->email) && isset($data->no_handphone) && isset($data->alamat)) {
            $id_user = $data->id_user;
            $nama = $data->nama;
            $email = $data->email;
            $no_handphone = $data->no_handphone;
            $alamat = $data->alamat;
            
            $query = "UPDATE user SET nama=?, email=?, no_handphone=?, alamat=? WHERE id_user=?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("ssssi", $nama, $email, $no_handphone, $alamat, $id_user);
            
            if($stmt->execute()) {
                echo json_encode(["message" => "User updated successfully"]);
            } else {
                echo json_encode(["error" => "Failed to update user"]);
            }
        }
        break;
        
    case 'DELETE':
        // Delete user
        $data = json_decode(file_get_contents("php://input"));
        
        if(isset($data->id_user)) {
            $id_user = $data->id_user;
            
            $query = "DELETE FROM user WHERE id_user=?";
            $stmt = $conn->prepare($query);
            $stmt->bind_param("i", $id_user);
            
            if($stmt->execute()) {
                echo json_encode(["message" => "User deleted successfully"]);
            } else {
                echo json_encode(["error" => "Failed to delete user"]);
            }
        }
        break;
}

$conn->close();
?>