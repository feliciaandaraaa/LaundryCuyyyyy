<?php
include 'config.php';

// Get all laundry services
$query = "SELECT * FROM laundry_services WHERE harga > 0";
$result = $conn->query($query);

$services = [];
while($row = $result->fetch_assoc()) {
    $services[] = $row;
}

echo json_encode($services);
$conn->close();
?>