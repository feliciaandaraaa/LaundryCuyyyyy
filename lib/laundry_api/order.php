<?php
include 'config.php';

$id_order = $_POST['id_order'];

$sql = "DELETE FROM orders WHERE id_order='$id_order'";
if ($conn->query($sql) === TRUE) {
  echo json_encode(["success" => true, "message" => "Order berhasil dihapus"]);
} else {
  echo json_encode(["success" => false, "message" => $conn->error]);
}

$conn->close();
?>
