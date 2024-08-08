defmodule AIS.Geo.QuadKeyTree do
  alias AIS.Geo.QuadKeyTree

  defstruct count: 0, nodes: [], key: 0, level: 0, children: []

  def create() do
    %QuadKeyTree{
      nodes: [
        %QuadKeyTree{key: 0, level: 1},
        %QuadKeyTree{key: 1, level: 1},
        %QuadKeyTree{key: 2, level: 1},
        %QuadKeyTree{key: 3, level: 1}
      ]
    }
  end

  @doc """
  Insert entity into tree given quadkey.

  Return a new tree with the entity inserted.
  """
  def insert(tree, quadkey, entity) do
    insert_entity(tree, tree.level + 1, quadkey, entity)
  end

  @doc """
  Get child entities from tree for given quadkey
  """
  def query(tree, quadkey) do
    zoom = String.length(quadkey)

    group_zoom =
      cond do
        zoom == 2 -> 6
        zoom == 3 -> 7
        zoom == 4 -> 8
        zoom == 5 -> 9
        true -> 15
      end

    query_group(tree, quadkey, group_zoom)
  end

  @doc """
  Remove given entity at quadkey.

  Return a new tree with entity removed if present
  """
  def remove(tree, quadkey, entity) do
    if quadkey do
      try do
        i = String.to_integer(String.first(quadkey))
        subkey = String.slice(quadkey, 1..-1//1)
        node = Enum.at(tree.nodes, i)
        count = tree.count

        if tree.nodes != [] do
          new_nodes =
            if subkey == "" do
              tree.nodes
              |> List.replace_at(i, %QuadKeyTree{
                node
                | children: Enum.filter(node.children, fn x -> x != entity end)
              })
            else
              tree.nodes
              |> List.replace_at(i, remove(node, subkey, entity))
            end

          %QuadKeyTree{tree | nodes: new_nodes, count: count - 1}
        else
          tree
        end
      rescue
        e ->
          IO.puts("remove exception: #{inspect(quadkey)} #{inspect(e)}")
          tree
      end
    else
      tree
    end
  end

  def count(tree) do
    if has_subnodes?(tree) do
      tree.nodes
      |> Enum.map(fn node ->
        count(node)
      end)
      |> Enum.concat()
    else
      [Enum.count(tree.children)]
    end
  end

  defp query_group(tree, quadkey, group_zoom) do
    # Query the tree to find children that fall within the tile
    # defined by the quadkey. If the level within the tree is below
    # the group_zoom level then return the first child in the list
    # if not then return all children
    i = String.to_integer(String.first(quadkey))
    subkey = String.slice(quadkey, 1..-1//1)

    if subkey != "" do
      if has_subnodes?(tree) do
        query_group(Enum.at(tree.nodes, i), subkey, group_zoom)
      else
        if tree.level > group_zoom do
          if tree.children != [], do: Enum.take(tree.children, 10), else: tree.children
        else
          tree.children
        end
      end
    else
      if has_subnodes?(tree) do
        query_group(Enum.at(tree.nodes, i), group_zoom)
      else
        if tree.level > group_zoom do
          if tree.children != [], do: Enum.take(tree.children, 10), else: tree.children
        else
          tree.children
        end
      end
    end
  end

  defp query_group(tree, group_zoom) do
    # No quadkey so simply collect all children at the leaf nodes below this tree
    # Return only the first child in the children list if we are below the
    # group_zoom level.
    if has_subnodes?(tree) do
      tree.nodes
      |> Enum.map(fn node ->
        query_group(node, group_zoom)
      end)
      |> Enum.concat()
    else
      if tree.level > group_zoom do
        if tree.children != [], do: Enum.take(tree.children, 10), else: tree.children
      else
        tree.children
      end
    end
  end

  defp has_subnodes?(%{nodes: nodes}) do
    length(nodes) > 0
  end

  defp insert_entity(tree, level, quadkey, entity) do
    if has_subnodes?(tree) do
      insert_entity(tree, level, quadkey, entity, :subnodes)
    else
      insert_entity(tree, level, quadkey, entity, :empty)
    end
  end

  #
  # This tree has subnodes, so an insert is basically finding the right
  # subnode to perform the insert on and replacing it in the
  # nodes map with the new tree.
  #
  defp insert_entity(tree, level, quadkey, entity, :subnodes) do
    i = String.to_integer(String.first(quadkey))
    subkey = String.slice(quadkey, 1..-1//1)
    node = Enum.at(tree.nodes, i)
    count = tree.count

    new_nodes =
      if subkey == "" do
        tree.nodes
        |> List.replace_at(i, %QuadKeyTree{
          node
          | children: node.children ++ [entity],
            level: level
        })
      else
        tree.nodes
        |> List.replace_at(i, insert_entity(node, level + 1, subkey, entity))
      end

    %QuadKeyTree{tree | nodes: new_nodes, count: count + 1}
  end

  defp insert_entity(tree, level, quadkey, entity, :empty) do
    nodes = [
      %QuadKeyTree{key: 0, level: level},
      %QuadKeyTree{key: 1, level: level},
      %QuadKeyTree{key: 2, level: level},
      %QuadKeyTree{key: 3, level: level}
    ]

    insert_entity(%QuadKeyTree{tree | nodes: nodes}, level, quadkey, entity, :subnodes)
  end
end
